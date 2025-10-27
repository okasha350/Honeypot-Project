# 🍯 Advanced Honeypot Network Monitoring System (Weeks 2-5)

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)  
[![Platform](https://img.shields.io/badge/Platform-Ubuntu%2022.04-orange.svg)]()  
[![Shell](https://img.shields.io/badge/Language-Shell%2FBash-green.svg)]()

A comprehensive solution for deploying and monitoring Honeypot systems to collect threat intelligence and analyze malicious activity within an isolated, controlled environment. This project covers network infrastructure setup, deployment of multiple honeypots, and the configuration of a centralized logging and evidence analysis system.

## 📋 Table of Contents

* [Overview](#overview)
* [Architecture](#architecture)
* [Features](#features)
* [Prerequisites](#prerequisites)
* [Project Structure](#project-structure)
* [Configuration & Usage](#configuration--usage)
* [Security Considerations](#security-considerations)

---

## 🎯 Overview

### Project Summary

The **Honeypot System Project** builds an isolated virtual environment simulating real servers to attract and record malicious activity. Captured attacks are analyzed to provide actionable insights for improving cybersecurity posture without risking production systems. The methodology includes deploying honeypots and monitoring VMs, collecting and analyzing logs, and producing dashboards, reports, and thorough documentation.

### Problem

Production networks and servers face daily attack attempts (web app exploits, malware delivery, SSH brute force, etc.). Observing and analyzing these attacks directly on production systems is risky and impractical.

### Solution

Deploy an isolated honeypot environment using virtual machines (VMs) running test services and specialized logging tools. Honeypots capture attacker behavior and forward telemetry securely to a centralized monitoring VM. Alerts, dashboards, and reports help detect threats and recommend security hardening steps. All testing is performed in a controlled, isolated environment.

---

## 🏗️ Architecture

Four VMs operate on an isolated network (VMnet2) to simulate a realistic production environment:

| Component         | OS           | IP Address       | Role                                                                   |
| ----------------- | ------------ | ---------------- | ---------------------------------------------------------------------- |
| **Honeypot VM**   | Ubuntu 22.04 | `192.168.100.10` | Hosts honeypots (Cowrie, Dionaea) and captures malicious traffic.      |
| **Monitoring VM** | Ubuntu 22.04 | `192.168.100.20` | Central log collection (syslog-ng), analysis, and evidence management. |
| **Sandbox VM**    | Ubuntu 22.04 | `192.168.100.30` | Isolated environment for malware analysis.                             |
| **Attacker VM**   | Kali Linux   | `192.168.100.50` | Attack simulation and targeted testing.                                |

---

## ✨ Features

### Week 2: Infrastructure Setup

* ✅ Isolated virtual network (VMnet2)
* ✅ Configure four VMs with static IP addresses
* ✅ Network connectivity check script (`scripts/network-check.sh`)
* ✅ Base VM snapshots

### Week 3: Honeypot Deployment & Log Aggregation

* ✅ Deploy **Cowrie SSH** honeypot (port 2222)
* ✅ Deploy multi-protocol **Dionaea** honeypot (via Docker)
* ✅ Centralized log collection using `syslog-ng` and forwarding to Monitoring VM
* ✅ Log monitoring and basic statistics script (`scripts/monitor-logs.sh`)

### Week 4: Evidence Handling & Isolated Analysis

* ✅ Setup isolated **Sandbox** VM for safe malware analysis
* ✅ Malware analysis script (`sandbox/analyze.sh`) using tools like ClamAV and `strings`
* ✅ **Chain-of-Custody** evidence documentation (`scripts/document-sample.sh`)
* ✅ Secure sample transfer script with integrity checks (`scripts/transfer-to-sandbox.sh`)
* ✅ Comprehensive system validation script (`scripts/full-system-check.sh`)

### 🌟 Week 5: Log Pipeline Troubleshooting & Finalization

* ✅ **Resolved Logstash/Docker Conflict:** Used Monitoring VM IP (`192.168.100.20`)
* ✅ **Repaired Syslog-ng Configuration:** Added missing `honeypot-receive.conf`
* ✅ **Confirmed Honeypot Port:** Cowrie actual port (**2222**)
* ✅ **Finalized Kibana Setup:** Created `honeypot-logs-*` index pattern and confirmed live log visibility
* ✅ Kibana access: [http://192.168.100.20:5602/](http://192.168.100.20:5602/)

---

## 🔧 Prerequisites

### Hardware Requirements

* **RAM:** Minimum 12 GB (16 GB recommended)
* **Storage:** 120 GB free disk space
* **CPU:** 4 cores or more

### Software Requirements

* Virtualization platform (VMware Workstation or VirtualBox)
* VM images/ISOs: Ubuntu 22.04 LTS and Kali Linux

---

## 📁 Project Structure

```
honeypot-system/
├── docs/
│   ├── week2-setup.md           # Network & infrastructure setup
│   ├── week3-setup.md           # Honeypot deployment & syslog-ng
│   ├── week4-setup.md           # Sandbox & evidence handling
│   └── week5-troubleshooting.md # Log pipeline & Kibana finalization
├── scripts/
│   ├── network-check.sh
│   ├── monitor-logs.sh
│   ├── document-sample.sh
│   ├── transfer-to-sandbox.sh
│   └── full-system-check.sh
├── config/
│   ├── honeypot/
│   │   ├── cowrie-syslog.conf
│   │   └── dionaea-syslog.conf
│   └── monitoring/
│       └── honeypot-receive.conf
├── sandbox/
│   └── analyze.sh
├── samples/    # Collected malware (gitignored)
├── evidence/   # Chain-of-custody records (gitignored)
├── reports/    # Final reports (gitignored)
├── .gitignore
├── LICENSE
└── README.md
```

---

## 🚀 Configuration & Usage

### 1. Clone

```bash
git clone https://github.com/YourUsername/honeypot-system.git
cd honeypot-system
```

### 2. Deployment

Follow the instructions in the `docs/` folder:

| Week | Docs File                     | Task                                         |
| ---- | ----------------------------- | -------------------------------------------- |
| 2    | docs/week2-setup.md           | Setup isolated network & static IPs          |
| 3    | docs/week3-setup.md           | Deploy Cowrie & Dionaea, configure syslog-ng |
| 4    | docs/week4-setup.md           | Setup Sandbox & evidence management          |
| 5    | docs/week5-troubleshooting.md | Resolve log pipeline issues, finalize Kibana |

### 3. Monitoring Scripts

Run these on the **Monitoring VM**:

| Script                 | Description                       | Command                            |
| ---------------------- | --------------------------------- | ---------------------------------- |
| full-system-check.sh   | Check network, services, and logs | `./scripts/full-system-check.sh`   |
| monitor-logs.sh        | Produce attack statistics         | `./scripts/monitor-logs.sh`        |
| document-sample.sh     | Start evidence documentation      | `./scripts/document-sample.sh`     |
| transfer-to-sandbox.sh | Securely transfer samples         | `./scripts/transfer-to-sandbox.sh` |

---

## 🔒 Security Considerations

* **Strict Network Isolation:** All VMs on private VMnet2; no direct Internet/host access except for updates.
* **Evidence Management:** Maintain accurate chain-of-custody; verify integrity via cryptographic hashes.
* **Isolated Analysis:** Never execute malware outside the Sandbox.
* **Snapshots:** Take VM snapshots before major changes or after key milestones.
