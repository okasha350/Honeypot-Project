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
