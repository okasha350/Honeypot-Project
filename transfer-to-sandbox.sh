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
