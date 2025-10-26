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
