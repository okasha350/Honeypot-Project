# Week 3: Honeypot Deployment and Centralized Logging

## Objective
Deploy and configure Cowrie SSH honeypot and Dionaea multi-protocol honeypot. Set up centralized log forwarding using `syslog-ng` from the Honeypot VM to the Monitoring VM.

## Architecture
```
Honeypot VM                    Monitoring VM
┌──────────────────┐          ┌──────────────────┐
│ Cowrie (Port 22) │          │                  │
│ Dionaea (Docker) │─────────▶│  syslog-ng       │
│ syslog-ng client │ TCP:514  │  (Log Storage)   │
└──────────────────┘          └──────────────────┘
```

## Part 1: Honeypot VM Setup (`192.168.100.10`)

### 1. Install Dependencies
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git python3 python3-pip python3-venv \
    build-essential libssl-dev libffi-dev python3-dev \
    curl wget docker.io docker-compose
```

### 2. Install Cowrie SSH Honeypot
**Create dedicated user:**
```bash
sudo adduser --disabled-password cowrie
sudo su - cowrie
```

**Download and setup:**
```bash
git clone https://github.com/cowrie/cowrie.git
cd cowrie
python3 -m venv cowrie-env
source cowrie-env/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
```

**Configure `cowrie.cfg`:**
```bash
cp etc/cowrie.cfg.dist etc/cowrie.cfg
# Edit etc/cowrie.cfg to set:
# hostname = honeypot-server
# [output_syslog] enabled = false
```

**Setup authbind for port 22:**
```bash
exit  # Return to regular user
sudo apt install -y authbind
sudo touch /etc/authbind/byport/22
sudo chown cowrie:cowrie /etc/authbind/byport/22
sudo chmod 755 /etc/authbind/byport/22
```

**Move real SSH to port 2222:**
```bash
sudo nano /etc/ssh/sshd_config
# Change Port 22 to Port 2222
# Add PermitRootLogin no
sudo systemctl restart sshd
```

**Create systemd service:**
```bash
sudo nano /etc/systemd/system/cowrie.service
```
**File: `config/honeypot/cowrie.service`** (Save this content to the service file)
```ini
[Unit]
Description=Cowrie SSH Honeypot
After=network.target

[Service]
Type=forking
User=cowrie
ExecStart=/usr/bin/authbind --deep /home/cowrie/cowrie/bin/cowrie start
ExecStop=/home/cowrie/cowrie/bin/cowrie stop
Restart=on-failure

[Install]
WantedBy=multi-user.target
```
```bash
sudo systemctl daemon-reload
sudo systemctl enable cowrie
sudo systemctl start cowrie
```

### 3. Install Dionaea (Docker)
```bash
mkdir -p ~/dionaea-docker/{logs,binaries}
cd ~/dionaea-docker

docker run -d \
  --name dionaea \
  --restart=always \
  -p 21:21 -p 42:42 -p 69:69/udp -p 80:80 \
  -p 135:135 -p 443:443 -p 445:445 -p 1433:1433 \
  -p 1723:1723 -p 1883:1883 -p 3306:3306 \
  -p 5060:5060 -p 5061:5061 \
  -v $(pwd)/logs:/opt/dionaea/var/log \
  -v $(pwd)/binaries:/opt/dionaea/var/lib/dionaea/binaries \
  dinotools/dionaea
```

### 4. Configure syslog-ng (Log Forwarding)
**Install:**
```bash
# ... (Installation commands as provided in the raw content)
sudo apt install -y syslog-ng-core
```

**Configure Cowrie forwarding:**
```bash
sudo nano /etc/syslog-ng/conf.d/cowrie.conf
```
**File: `config/honeypot/cowrie-syslog.conf`** (Save this content to the config file)
```conf
source s_cowrie {
    file(
        "/home/cowrie/cowrie/var/log/cowrie/cowrie.json"
        follow-freq(1)
        flags(no-parse)
    );
};

destination d_monitoring_cowrie {
    syslog(
        "192.168.100.20"
        transport("tcp")
        port(514)
        persist-name("cowrie_remote")
    );
};

log {
    source(s_cowrie);
    destination(d_monitoring_cowrie);
};
```

**Configure Dionaea forwarding:**
```bash
sudo nano /etc/syslog-ng/conf.d/dionaea.conf
```
**File: `config/honeypot/dionaea-syslog.conf`** (Save this content to the config file)
```conf
source s_dionaea {
    file(
        "/home/honeypot/dionaea-docker/logs/dionaea.log"
        follow-freq(1)
        flags(no-parse)
    );
};

destination d_monitoring_dionaea {
    syslog(
        "192.168.100.20"
        transport("tcp")
        port(514)
        persist-name("dionaea_remote")
    );
};

log {
    source(s_dionaea);
    destination(d_monitoring_dionaea);
};
```

**Set permissions and start:**
```bash
sudo usermod -a -G cowrie syslog
sudo chmod 755 /home/cowrie/cowrie/var/log/cowrie
# ... (Other chmod commands)
sudo systemctl enable syslog-ng
sudo systemctl start syslog-ng
```

## Part 2: Monitoring VM Setup (`192.168.100.20`)

### 1. Install syslog-ng
```bash
# ... (Installation commands as provided in the raw content)
sudo apt install -y syslog-ng-core
```

### 2. Configure Log Reception
**Edit main config:**
```bash
sudo nano /etc/syslog-ng/syslog-ng.conf
# Ensure source s_src includes network reception on port 514 TCP
```

**Create log storage config:**
```bash
sudo nano /etc/syslog-ng/conf.d/honeypot.conf
```
**File: `config/monitoring/honeypot-receive.conf`** (Save this content to the config file)
```conf
# Destinations for log storage
destination d_cowrie {
    file(
        "/var/log/honeypot/cowrie.log"
        create-dirs(yes)
        owner("root")
        group("root")
        perm(0644)
    );
};

destination d_dionaea {
    file(
        "/var/log/honeypot/dionaea.log"
        create-dirs(yes)
        owner("root")
        group("root")
        perm(0644)
    );
};

destination d_all_logs {
    file(
        "/var/log/honeypot/all.log"
        create-dirs(yes)
        owner("root")
        group("root")
        perm(0644)
    );
};

# Filters to separate logs (based on content, adjust as needed)
filter f_cowrie {
    match("cowrie" value("MESSAGE"))
    or match("eventid" value("MESSAGE"))
    or match("login attempt" value("MESSAGE"));
};

filter f_dionaea {
    match("dionaea" value("MESSAGE"))
    or match("connection" value("MESSAGE"));
};

# Log paths
log {
    source(s_src);
    filter(f_cowrie);
    destination(d_cowrie);
    flags(flow-control);
};

log {
    source(s_src);
    filter(f_dionaea);
    destination(d_dionaea);
    flags(flow-control);
};

log {
    source(s_src);
    destination(d_all_logs);
    flags(flow-control);
};
```

**Start syslog-ng:**
```bash
sudo mkdir -p /var/log/honeypot
sudo chmod 755 /var/log/honeypot
sudo systemctl enable syslog-ng
sudo systemctl start syslog-ng
```

## Part 3: Testing & Monitoring Scripts

### 1. Attack Simulation (`Attacker VM`)
```bash
# SSH attacks
# Note: sshpass is required on Attacker VM for this test
sudo apt install sshpass -y
for i in {1..20}; do
    sshpass -p "test$i" ssh -o StrictHostKeyChecking=no root@192.168.100.10 "ls" 2>/dev/null
    sleep 0.5
done

# FTP attacks
for i in {1..10}; do
    curl ftp://192.168.100.10 --user "test$i:pass$i" 2>/dev/null
    sleep 0.5
done
```

### 2. Monitoring Script (`Monitoring VM`)
**File: `scripts/monitor-logs.sh`**
```bash
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
```

Save the script to `~/honeypot-project/scripts/monitor-logs.sh` and run:
```bash
chmod +x ~/honeypot-project/scripts/monitor-logs.sh
~/honeypot-project/scripts/monitor-logs.sh
```

This concludes the honeypot deployment and centralized logging setup. Proceed to Week 4 for sandbox and evidence management.
