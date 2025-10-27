# 🍯 Advanced Honeypot Network Monitoring System (Weeks 2-5)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)  
[![Platform](https://img.shields.io/badge/Platform-Ubuntu%2022.04-orange.svg)]()  
[![Shell](https://img.shields.io/badge/Language-Shell%2FBash-green.svg)]()

A comprehensive solution for deploying and monitoring Honeypot systems to collect threat intelligence and analyze malicious activity within an isolated, controlled environment. This project covers network infrastructure setup, deployment of multiple honeypots, and the configuration of a centralized logging and evidence analysis system.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Configuration & Usage](#configuration--usage)
- [Security Considerations](#security-considerations)

---

## 🎯 Overview

### Project Summary

The **Honeypot System Project** aims to build an isolated virtual environment that simulates real servers to attract and record malicious activity. Captured attacks are analyzed to provide actionable insights for improving cybersecurity posture without risking production systems. The methodology includes deploying honeypots and monitoring VMs, collecting and analyzing logs, and producing dashboards, reports, and thorough documentation.

### Problem

Production networks and servers are subject to daily attack attempts (web app exploits, malware delivery, SSH brute force, etc.). Observing and analyzing these attacks directly on production systems is risky and impractical.

### Solution

Deploy an isolated honeypot environment using virtual machines (VMs) running test services and specialized logging tools. The honeypot captures attacker behavior and forwards telemetry securely to a centralized monitoring VM for analysis. Alerts, dashboards, and reports help detect threats and recommend security hardening steps. All testing is performed in a controlled, isolated environment.

---

## 🏗️ Architecture

The system consists of four virtual machines operating on an isolated network (VMnet2) to simulate a realistic production environment.

| Component | OS | IP Address | Role |
|---|---:|---:|---|
| **Honeypot VM** | Ubuntu 22.04 | `192.168.100.10` | Hosts honeypots (Cowrie, Dionaea) and captures malicious traffic. |
| **Monitoring VM** | Ubuntu 22.04 | `192.168.100.20` | Central log collection (syslog-ng), analysis, and evidence management. |
| **Sandbox VM** | Ubuntu 22.04 | `192.168.100.30` | Isolated environment for malware analysis. |
| **Attacker VM** | Kali Linux | `192.168.100.50` | Attack simulation and targeted testing. |

---

## ✨ Features

This repository covers the core stages of the project from Week 2 through Week **5**.

### Week 2: Infrastructure Setup
- ✅ Isolated virtual network (VMnet2).
- ✅ Configure four VMs with static IP addresses.
- ✅ Network connectivity check script (`scripts/network-check.sh`).
- ✅ Base VM snapshots.

### Week 3: Honeypot Deployment & Log Aggregation
- ✅ Deploy **Cowrie SSH** honeypot (port 22).
- ✅ Deploy multi-protocol **Dionaea** honeypot (via Docker).
- ✅ Centralized log collection using `syslog-ng` and forwarding to Monitoring VM.
- ✅ Log monitoring and basic statistics script (`scripts/monitor-logs.sh`).

### Week 4: Evidence Handling & Isolated Analysis
- ✅ Setup an isolated **Sandbox** VM for safe malware analysis.
- ✅ Malware analysis script (`sandbox/analyze.sh`) using tools such as ClamAV and `strings`.
- ✅ **Chain-of-Custody** evidence documentation (`scripts/document-sample.sh`).
- ✅ Secure sample transfer script with integrity checks (hashing) (`scripts/transfer-to-sandbox.sh`).
- ✅ Comprehensive system validation script (`scripts/full-system-check.sh`).

### 🌟 Week 5: Log Pipeline Troubleshooting and Finalization
- ✅ **Resolved Logstash/Docker Conflict:** Fixed the connection issue by using the host machine's IP (`192.168.100.20`).
- ✅ **Repaired Syslog-ng Configuration:** Configured the missing log forwarding file (`honeypot-receive.conf`).
- ✅ **Confirmed Honeypot Port:** Identified and utilized Cowrie's actual listening port (**2222**).
- ✅ **Finalized Kibana Setup:** Created the `honeypot-logs-*` Index Pattern and confirmed live log visibility.
- ✅ Access to Kibana finalized at: `http://192.168.100.20:5602/`

---

## 🔧 Prerequisites

### Hardware requirements:
- **RAM:** Minimum 12 GB (16 GB recommended).
- **Storage:** 120 GB free disk space.
- **CPU:** 4 cores or more.

### Software requirements:
- Virtualization platform (e.g., VMware Workstation or VirtualBox).
- VM images/ISOs: Ubuntu 22.04 LTS and Kali Linux.

---

## 📁 Project Structure

honeypot-system/├── docs/                          # Setup and configuration guides for each week│   ├── week2-setup.md             # Network and infrastructure setup guide│   ├── week3-setup.md             # Honeypot deployment and syslog-ng configuration│   ├── week4-setup.md             # Sandbox setup and evidence handling guide│   └── week5-troubleshooting.md   # Log pipeline troubleshooting and Kibana finalization (New)│├── scripts/                       # Automation and monitoring scripts (run on Monitoring VM)│   ├── network-check.sh           # Network connectivity tests│   ├── monitor-logs.sh            # Basic attack statistics and summaries│   ├── document-sample.sh         # Start a chain-of-custody record for new evidence│   ├── transfer-to-sandbox.sh     # Securely transfer a documented sample to the Sandbox│   └── full-system-check.sh       # Full system health and service checks│├── config/                        # Configuration files for honeypots and syslog-ng│   ├── honeypot/│   │   ├── cowrie-syslog.conf     # Cowrie syslog-ng config (Honeypot VM)│   │   └── dionaea-syslog.conf    # Dionaea syslog-ng config (Honeypot VM)│   ││   └── monitoring/│       └── honeypot-receive.conf  # Log receiver configuration (Monitoring VM)│├── sandbox/                       # Analysis scripts (run on Sandbox VM)│   └── analyze.sh                 # Malware analysis automation script│├── samples/                       # Collected sample storage (gitignored)├── evidence/                      # Chain-of-custody records (gitignored)├── reports/                       # Final reports (gitignored)├── .gitignore                     # Files to ignore in Git├── LICENSE                        # MIT License└── README.md                      # This file
---

## 🚀 Configuration & Usage

### 1. Clone
```bash
git clone [https://github.com/YourUsername/honeypot-system.git](https://github.com/YourUsername/honeypot-system.git)
cd honeypot-system
2. DeploymentFollow the detailed instructions in the docs/ folder to configure the VMs and deploy services.WeekDocs FileTask2docs/week2-setup.mdSet up the isolated network and assign static IPs.3docs/week3-setup.mdDeploy Cowrie and Dionaea, and configure syslog-ng.4docs/week4-setup.mdPrepare the Sandbox and evidence management procedures.5docs/week5-troubleshooting.mdResolve log pipeline issues and finalize Kibana setup.3. Monitoring ScriptsUse the following scripts on the Monitoring VM after the environment is configured:ScriptDescriptionRun commandfull-system-check.shComprehensive check of all system components (network, services, logs)../scripts/full-system-check.shmonitor-logs.shProduce attack statistics (SSH/FTP attempts, top attacking IP addresses)../scripts/monitor-logs.shdocument-sample.shStart documenting a new piece of evidence (chain-of-custody)../scripts/document-sample.shtransfer-to-sandbox.shSecurely transfer a documented sample to the Sandbox VM../scripts/transfer-to-sandbox.sh🔒 Security ConsiderationsStrict network isolation: Keep all VMs on a private virtual network (VMnet2) with no direct Internet or host network access except for necessary initial updates.Evidence management: Maintain accurate chain-of-custody records for each collected sample and verify integrity using cryptographic hashes.Isolated analysis: Never execute collected malware outside the dedicated Sandbox environment.Snapshots: Take VM snapshots before major changes or after each key milestone.
