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
