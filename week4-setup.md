# Week 4: Sandbox & Evidence Management

## Objective
Establish an isolated malware analysis environment on the Sandbox VM and implement a secure chain of custody system on the Monitoring VM.

## Architecture
```
Honeypot VM                Monitoring VM              Sandbox VM
┌────────────┐            ┌──────────────┐          ┌────────────┐
│  Collect   │───────────▶│   Document   │─────────▶│   Analyze  │
│  Samples   │   scp      │   Evidence   │   SSH    │   Safely   │
└────────────┘            └──────────────┘          └────────────┘
```

## Part 1: Sandbox VM Setup (`192.168.100.30`)

### 1. Install Analysis Tools
```bash
sudo apt update
sudo apt install -y python3 python3-pip git curl wget \
    file binutils strings hexdump clamav clamav-daemon \
    net-tools tcpdump wireshark nmap
```

**Update ClamAV:**
```bash
sudo systemctl stop clamav-freshclam
sudo freshclam
sudo systemctl start clamav-freshclam
```

### 2. Create Working Directories
```bash
mkdir -p ~/samples
mkdir -p ~/analysis-reports
```

### 3. Automated Analysis Script
**File: `sandbox/analyze.sh`**
```bash
#!/bin/bash
# Brief: Performs basic static analysis on a collected malware sample.

if [ -z "$1" ]; then
    echo "Usage: $0 <sample_file>"
    exit 1
fi

SAMPLE="$1"
REPORT_DIR="$HOME/analysis-reports"
DATE=$(date +%Y-%m-%d_%H-%M-%S)
REPORT="$REPORT_DIR/report-$DATE-$(basename $SAMPLE).txt"

echo "Analyzing: $SAMPLE"
echo "Report: $REPORT"
{
    echo "========================================="
    echo "MALWARE ANALYSIS REPORT"
    echo "========================================="
    echo ""
    echo "Date: $(date)"
    echo "Sample: $SAMPLE"
    echo "Analyst: $(whoami)@$(hostname)"
    echo ""

    echo "========================================="
    echo "1. FILE INFORMATION"
    echo "========================================="
    file "$SAMPLE"
    echo "File Size: $(stat -c%s "$SAMPLE") bytes"
    echo ""

    echo "========================================="
    echo "2. HASH VALUES"
    echo "========================================="
    echo "MD5:    $(md5sum "$SAMPLE" | awk '{print $1}')"
    echo "SHA1:   $(sha1sum "$SAMPLE" | awk '{print $1}')"
    echo "SHA256: $(sha256sum "$SAMPLE" | awk '{print $1}')"
    echo ""

    echo "========================================="
    echo "3. STRINGS ANALYSIS (First 50)"
    echo "========================================="
    strings "$SAMPLE" | head -50
    echo ""

    echo "========================================="
    echo "4. HEXDUMP (First 256 bytes)"
    echo "========================================="
    hexdump -C "$SAMPLE" | head -20
    echo ""

    echo "========================================="
    echo "5. CLAMAV SCAN"
    echo "========================================="
    clamscan "$SAMPLE"
    echo ""

    echo "========================================="
    echo "ANALYSIS COMPLETE"
    echo "========================================="
} > "$REPORT"
echo "✓ Analysis complete!"
echo "Report: $REPORT"
```
```bash
chmod +x ~/analyze.sh
# Move to project structure
mv ~/analyze.sh ~/honeypot-project/sandbox/
```

## Part 2: Monitoring VM - Evidence Management (`192.168.100.20`)

### 1. SSH Key Setup
The Monitoring VM must be able to securely transfer files to the Sandbox VM without a password.
```bash
# Generate SSH key
ssh-keygen -t rsa -b 2048 -N "" -f ~/.ssh/id_rsa

# Copy to Sandbox (assuming a user 'sandbox' exists on 192.168.100.30)
ssh-copy-id sandbox@192.168.100.30
```

### 2. Chain of Custody Script
**File: `scripts/document-sample.sh`**
```bash
#!/bin/bash
# Brief: Creates a chain of custody record for a collected sample.

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

SAMPLES_DIR="$HOME/honeypot-project/samples"
EVIDENCE_DIR="$HOME/honeypot-project/evidence"
DATE=$(date +%Y-%m-%d_%H-%M-%S)

echo "========================================"
echo -e "${BLUE}Chain of Custody Documentation${NC}"
echo "========================================"
echo ""

read -p "Sample filename: " SAMPLE_NAME
read -p "Source (e.g., Dionaea): " SOURCE
read -p "Your name: " ANALYST
read -p "Description: " DESCRIPTION

if [ ! -f "$SAMPLES_DIR/$SAMPLE_NAME" ]; then
    echo -e "${YELLOW}Warning: Sample not found at $SAMPLES_DIR/$SAMPLE_NAME${NC}"
    read -p "Continue? (y/n): " CONTINUE
    [ "$CONTINUE" != "y" ] && exit 1
fi

if [ -f "$SAMPLES_DIR/$SAMPLE_NAME" ]; then
    MD5=$(md5sum "$SAMPLES_DIR/$SAMPLE_NAME" | awk '{print $1}')
    SHA256=$(sha256sum "$SAMPLES_DIR/$SAMPLE_NAME" | awk '{print $1}')
    SIZE=$(stat -c%s "$SAMPLES_DIR/$SAMPLE_NAME")
else
    MD5="N/A"
    SHA256="N/A"
    SIZE="N/A"
fi

EVIDENCE_ID="EVD-$DATE-$(echo $RANDOM | md5sum | head -c 6)"
EVIDENCE_FILE="$EVIDENCE_DIR/$EVIDENCE_ID.md"

cat > "$EVIDENCE_FILE" << EOF
# CHAIN OF CUSTODY RECORD: $EVIDENCE_ID

**Date/Time:** $(date)

## SAMPLE INFORMATION
| Field | Value |
|---|---|
| **Filename** | $SAMPLE_NAME |
| **Source** | $SOURCE |
| **Description** | $DESCRIPTION |

## HASH VALUES
| Algorithm | Value |
|---|---|
| **MD5** | $MD5 |
| **SHA256** | $SHA256 |
| **File Size** | $SIZE bytes |

## CUSTODY CHAIN
| Step | Action | Date/Time | Location | Custodian |
|---|---|---|---|---|
| **[1]** | Initial collection from $SOURCE | $(date) | $SAMPLES_DIR | $ANALYST |
EOF

echo ""
echo -e "${GREEN}✓ Documentation complete!${NC}"
echo "Evidence ID: $EVIDENCE_ID"
echo "MD5: $MD5"
echo "SHA256: $SHA256"
echo "File: $EVIDENCE_FILE"
```
```bash
chmod +x ~/honeypot-project/scripts/document-sample.sh
```

### 3. Secure Transfer Script
**File: `scripts/transfer-to-sandbox.sh`**
```bash
#!/bin/bash
# Brief: Securely transfers a sample to the Sandbox VM and verifies integrity.

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

SAMPLES_DIR="$HOME/honeypot-project/samples"
SANDBOX_IP="192.168.100.30"
SANDBOX_USER="sandbox"

echo "========================================"
echo "  Secure Sample Transfer"
echo "========================================"
echo ""

echo "Available samples:"
ls -lh "$SAMPLES_DIR"
echo ""

read -p "Sample filename: " SAMPLE_NAME

if [ ! -f "$SAMPLES_DIR/$SAMPLE_NAME" ]; then
    echo -e "${RED}Error: Sample not found!${NC}"
    exit 1
fi

echo ""
echo "Calculating hash..."
MD5_BEFORE=$(md5sum "$SAMPLES_DIR/$SAMPLE_NAME" | awk '{print $1}')
echo "MD5: $MD5_BEFORE"

echo ""
echo "Transferring to Sandbox..."
scp "$SAMPLES_DIR/$SAMPLE_NAME" "$SANDBOX_USER@$SANDBOX_IP:~/samples/"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Transfer successful!${NC}"

    echo ""
    echo "Verifying integrity..."
    MD5_AFTER=$(ssh "$SANDBOX_USER@$SANDBOX_IP" "md5sum ~/samples/$SAMPLE_NAME" | awk '{print $1}')

    if [ "$MD5_BEFORE" == "$MD5_AFTER" ]; then
        echo -e "${GREEN}✓ Integrity verified!${NC}"
        echo "MD5: $MD5_AFTER"
    else
        echo -e "${RED}✗ Hash mismatch!${NC}"
        echo "Before: $MD5_BEFORE"
        echo "After: $MD5_AFTER"
    fi
else
    echo -e "${RED}✗ Transfer failed!${NC}"
    exit 1
fi

echo ""
echo "========================================"
```
```bash
chmod +x ~/honeypot-project/scripts/transfer-to-sandbox.sh
```

## Part 3: System Health Check

**File: `scripts/full-system-check.sh`**
```bash
#!/bin/bash
# Brief: Comprehensive check of the entire honeypot system health and connectivity.

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "========================================"
echo -e "${BLUE}  FULL SYSTEM CHECK${NC}"
echo "========================================"
echo ""

PASS=0
FAIL=0

# Network tests (Pinging Honeypot, Sandbox, Attacker)
echo -e "${YELLOW}=== NETWORK (Monitoring VM) ===${NC}"
for ip in 192.168.100.10 192.168.100.30 192.168.100.50; do
    echo -n "Ping $ip: "
    if ping -c 1 -W 2 $ip > /dev/null 2>&1; then
        echo -e "${GREEN}✓${NC}"
        ((PASS++))
    else
        echo -e "${RED}✗${NC}"
        ((FAIL++))
    fi
done
echo ""

# Honeypot services (Checking ports on Honeypot VM)
echo -e "${YELLOW}=== HONEYPOT SERVICES (192.168.100.10) ===${NC}"
echo -n "SSH Port 22 (Cowrie): "
if nc -z -w 2 192.168.100.10 22 > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
    ((PASS++))
else
    echo -e "${RED}✗${NC}"
    ((FAIL++))
fi

echo -n "FTP Port 21 (Dionaea): "
if nc -z -w 2 192.168.100.10 21 > /dev/null 2>&1; then
    echo -e "${GREEN}✓${NC}"
    ((PASS++))
else
    echo -e "${RED}✗${NC}"
    ((FAIL++))
fi
echo ""

# Logs (Checking log files on Monitoring VM)
echo -e "${YELLOW}=== LOG RECEPTION (Monitoring VM) ===${NC}"
echo -n "Cowrie logs received: "
if [ -f /var/log/honeypot/cowrie.log ] && [ -s /var/log/honeypot/cowrie.log ]; then
    echo -e "${GREEN}✓${NC}"
    ((PASS++))
else
    echo -e "${RED}✗${NC}"
    ((FAIL++))
fi

echo -n "Dionaea logs received: "
if [ -f /var/log/honeypot/dionaea.log ] && [ -s /var/log/honeypot/dionaea.log ]; then
    echo -e "${GREEN}✓${NC}"
    ((PASS++))
else
    echo -e "${RED}✗${NC}"
    ((FAIL++))
fi
echo ""

# Sandbox SSH Access (Checking key-based login)
echo -e "${YELLOW}=== SANDBOX ACCESS (192.168.100.30) ===${NC}"
echo -n "SSH Key Access: "
if ssh -o BatchMode=yes -o ConnectTimeout=2 sandbox@192.168.100.30 "exit" 2>/dev/null; then
    echo -e "${GREEN}✓${NC}"
    ((PASS++))
else
    echo -e "${RED}✗${NC}"
    ((FAIL++))
fi
echo ""

# Summary
echo "========================================"
echo -e "${GREEN}Passed: $PASS${NC}"
echo -e "${RED}Failed: $FAIL${NC}"
echo ""

if [ $FAIL -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
else
    echo -e "${YELLOW}⚠️  Some tests failed. Check logs and configuration.${NC}"
fi
```
```bash
chmod +x ~/honeypot-project/scripts/full-system-check.sh
```

This concludes the setup for Week 4. The project is now ready for controlled testing and analysis.
