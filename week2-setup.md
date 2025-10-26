# Week 2: Network Infrastructure Setup

## Objective
Establish an isolated virtual network environment and configure four virtual machines (VMs) with static IP addresses.

## Architecture & Specifications

| Component | OS | RAM | Disk | Network | IP Address | Role |
|---|---|---|---|---|---|---|
| **Honeypot VM** | Ubuntu 22.04 | 2GB | 25GB | VMnet2 | `192.168.100.10` | Honeypot Deployment |
| **Monitoring VM** | Ubuntu 22.04 | 4GB | 50GB | VMnet2 | `192.168.100.20` | Log Aggregation & Analysis |
| **Sandbox VM** | Ubuntu 22.04 | 2GB | 25GB | VMnet2 | `192.168.100.30` | Malware Analysis |
| **Attacker VM** | Kali Linux | 2GB | 20GB | VMnet2 | `192.168.100.50` | Controlled Testing |

## Step 1: Virtual Network Configuration (VMware Workstation)

1.  Open **Virtual Network Editor** (Admin privileges required).
2.  Add a new network named **VMnet2**.
3.  Set the type to **Host-only**.
4.  Configure Subnet IP: `192.168.100.0`
5.  Configure Subnet Mask: `255.255.255.0`
6.  **Disable** "Use local DHCP service to distribute IP addresses to VMs".

## Step 2: VM Installation and Static IP Configuration

For each Ubuntu VM (Honeypot, Monitoring, Sandbox), follow these steps:

1.  Install Ubuntu 22.04 LTS.
2.  Edit VM Settings -> Network Adapter -> Custom: **VMnet2 (Host-only)**.
3.  Configure static IP (replace `X` with `.10`, `.20`, or `.30`):

    ```bash
    # Edit Netplan configuration
    sudo nano /etc/netplan/00-installer-config.yaml
    ```

    Replace content with:
    ```yaml
    network:
      version: 2
      renderer: networkd
      ethernets:
        eth0: # Check your interface name, might be different (e.g., ens33)
          dhcp4: no
          addresses: [192.168.100.X/24]
          nameservers:
            addresses: [8.8.8.8, 8.8.4.4] # For initial package updates
    ```

4.  Apply changes:
    ```bash
    sudo netplan apply
    ```

For **Attacker VM (Kali Linux)**:

1.  Download and open the Kali VMware image.
2.  Edit VM Settings -> Network Adapter -> Custom: **VMnet2 (Host-only)**.
3.  Configure static IP (`192.168.100.50`):

    ```bash
    sudo nano /etc/network/interfaces
    ```

    Add:
    ```
    auto eth0
    iface eth0 inet static
        address 192.168.100.50
        netmask 255.255.255.0
        gateway 192.168.100.1
    ```

4.  Restart networking:
    ```bash
    sudo systemctl restart networking
    # OR
    sudo reboot
    ```

## Step 3: Verification

Run the following script on the **Monitoring VM** to confirm connectivity:

```bash
# Create network-check.sh in scripts directory
nano ~/honeypot-project/scripts/network-check.sh
```

**File: `scripts/network-check.sh`**
```bash
#!/bin/bash
# Brief: Checks network connectivity between all project VMs.

echo "=== Network Connectivity Test ==="
for ip in 192.168.100.10 192.168.100.20 192.168.100.30 192.168.100.50; do
    echo -n "Testing $ip: "
    ping -c 1 -W 2 $ip > /dev/null 2>&1 && echo "✓ OK" || echo "✗ FAIL"
done
```

Run:
```bash
chmod +x ~/honeypot-project/scripts/network-check.sh
~/honeypot-project/scripts/network-check.sh
```

**Expected Output:** All tests should show `✓ OK`.

## Step 4: Create Baseline Snapshots

For each VM, create a snapshot named: `Week 2 Complete - Clean Install`.

This concludes the infrastructure setup. Proceed to Week 3 for honeypot deployment.
