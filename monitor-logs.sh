#!/bin/bash
# Brief: Displays basic statistics from collected honeypot logs.

echo "=== Honeypot Statistics ==="
SSH_ATTEMPTS=$(sudo grep -c "login attempt" /var/log/honeypot/cowrie.log 2>/dev/null || echo "0")
echo "SSH Login Attempts: $SSH_ATTEMPTS"

FTP_ATTEMPTS=$(sudo grep -c "ftp" /var/log/honeypot/dionaea.log 2>/dev/null || echo "0")
echo "FTP Attempts: $FTP_ATTEMPTS"

echo ""
echo "Top 5 Attacker IPs (from Cowrie):"
sudo grep "login attempt" /var/log/honeypot/cowrie.log 2>/dev/null | \
    grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' | \
    sort | uniq -c | sort -rn | head -5
