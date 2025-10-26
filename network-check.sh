#!/bin/bash
# Brief: Checks network connectivity between all project VMs.

echo "=== Network Connectivity Test ==="
for ip in 192.168.100.10 192.168.100.20 192.168.100.30 192.168.100.50; do
    echo -n "Testing $ip: "
    ping -c 1 -W 2 $ip > /dev/null 2>&1 && echo "✓ OK" || echo "✗ FAIL"
done
