# Week 5: Log Pipeline Troubleshooting and ELK Stack Finalization

## 🎯 Objective

Resolve critical communication failures in the centralized logging pipeline (**Syslog-ng → Logstash**) and successfully finalize the ELK Stack configuration to visualize threat data in Kibana. This phase ensures robust log collection and validation.

## 🏗️ Architecture Flow (Final State)

The log flow is stabilized. Logs are forwarded by Syslog-ng on the **Monitoring VM** to the local Logstash Docker container using the host's actual network IP (`192.168.100.20`), bypassing loopback issues.

| Component | Port Used | IP Target | Status |
|---|---|---|---|
| **Cowrie Honeypot** | **22** (Listened Port) | N/A | **Fixed** (Confirmed port trap) |
| **Syslog-ng (Forwarding)** | **5000** (Outbound) | `192.168.100.20` | **Fixed** (Updated destination IP) |
| **Logstash (Docker)** | **5000** (Inbound) | `0.0.0.0` (Bound internally) | **Working** (Accessible via Host IP) |
| **Kibana Access** | **5602** (Web UI) | `192.168.100.20` | **Finalized** |

---

## Part 1: Initial ELK Stack Installation (Monitoring VM: 192.168.100.20)

These steps cover the complete setup of Docker and the ELK stack components.

### 1.1 Install Dependencies and Docker

```bash
# Update system and install necessary packages
sudo apt update
sudo apt install -y curl wget apt-transport-https

# Install Docker and Docker Compose
sudo apt install -y docker.io docker-compose

# Start and enable Docker service
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to the docker group (required to run docker without sudo)
sudo usermod -aG docker $USER
# NOTE: Log out and log back in for group change to take effect
```

### 1.2 Setup ELK Stack (Docker Compose)

We create the directory structure and the main docker-compose.yml file.

```bash
# Create directory structure for Logstash configs
mkdir -p logstash/pipeline
mkdir -p logstash/config

# Create the Docker Compose file
sudo nano docker-compose.yml
# Content for docker-compose.yml (Save this content to the file)
```

```yaml
version: '3.7'
services:
  elasticsearch:
    image: docker.elastic.co/elasticsearch/elasticsearch:7.17.6
    container_name: elasticsearch
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
    ulimits:
      memlock:
        soft: -1
        hard: -1
    volumes:
      - esdata:/usr/share/elasticsearch/data
    networks:
      - elknet

  logstash:
    image: docker.elastic.co/logstash/logstash:7.17.6
    container_name: logstash
    # Expose port 5000 for Syslog-ng input on the host machine
    ports:
      - "5000:5000/tcp"
    environment:
      - LS_JAVA_OPTS="-Xmx256m -Xms256m"
    volumes:
      - ./logstash/config:/usr/share/logstash/config
      - ./logstash/pipeline:/usr/share/logstash/pipeline
    depends_on:
      - elasticsearch
    networks:
      - elknet

  kibana:
    image: docker.elastic.co/kibana/kibana:7.17.6
    container_name: kibana
    # Expose port 5602 for web access (Mapping container port 5601 to host port 5602)
    ports:
      - "5602:5601"
    environment:
      ELASTICSEARCH_URL: http://elasticsearch:9200
    depends_on:
      - elasticsearch
    networks:
      - elknet

volumes:
  esdata:
    driver: local

networks:
  elknet:
    driver: bridge
```

### 1.3 Setup Logstash Pipeline Configuration

The configuration tells Logstash to listen for JSON data on port 5000 (TCP) and index it in Elasticsearch.

```bash
# Create the main Logstash pipeline configuration file
sudo nano logstash/pipeline/syslog.conf
# Content for logstash/pipeline/syslog.conf (Save this content to the file)
```

```conf
input {
  tcp {
    port => 5000
    type => "honeypot"
    codec => json_lines
  }
}

filter {
  # Add the timestamp field from the log entry itself (optional, but good practice)
  date {
    match => ["@timestamp", "ISO8601"]
    target => "@timestamp"
  }
}

output {
  elasticsearch {
    hosts => ["http://elasticsearch:9200"]
    index => "honeypot-logs-%{+YYYY.MM.dd}"
  }
  # Enable stdout for debugging logs in the Docker terminal
  stdout { codec => rubydebug }
}
```

### 1.4 Start the ELK Stack

```bash
# Start the entire stack in detached mode
sudo docker-compose up -d

# Check if all services are running
sudo docker-compose ps
```

## Part 2: Syslog-ng Communication Fix (The Week 5 Core)

This section corrects the addressing error that prevented Syslog-ng from forwarding logs to Logstash.

### 2.1 Modify Syslog-ng Configuration File

We update the destination block (d_logstash) in honeypot-receive.conf to explicitly use the Monitoring VM's network IP (192.168.100.20) instead of the loopback interface.

```bash
# Edit the Syslog-ng configuration file responsible for log forwarding
sudo nano /etc/syslog-ng/conf.d/honeypot-receive.conf
```

**The Corrected Logstash Destination Block (Ensure this is in the file):**

```conf
# =================================================================
# FIX: Destination to Logstash 
# Changed IP from 127.0.0.1 to the Monitoring VM's actual IP (192.168.100.20)
# =================================================================

destination d_logstash {
    tcp("192.168.100.20" port(5000)
        template("$MSG\n") 
        template-escape(no)
    );
};

# ... (Ensure the log path at the bottom of the file is correct) ...
log {
    source(s_src);
    destination(d_logstash);
    flags(flow-control);
};
```

### 2.2 Restart Syslog-ng Service

```bash
# Restart the service to load the new destination IP
sudo systemctl restart syslog-ng

# Verify the service status
sudo systemctl status syslog-ng
```

## Part 3: Final Validation and Kibana Setup

### 3.1 Test Logstash Connection

Send a manual test message to confirm the communication fix.

```bash
# Command: Send a manual test message to Logstash via the fixed IP/Port 5000
echo '{"message": "Manual Logstash Connection Test Success", "honeypot_source": "manual_test_week5"}' | nc 192.168.100.20 5000
```

### 3.2 Generate Cowrie Logs

Trigger a log entry from the Honeypot VM to test the full pipeline.

```bash
# Command: Execute a simulated SSH attack targeting the honeypot port (22)
ssh -o StrictHostKeyChecking=no testuser@192.168.100.10
```

### 3.3 Kibana Access and Index Creation

Access Kibana: Open the web interface. Access URL: http://192.168.100.20:5602/

**Create Index Pattern (Kibana UI Steps):**

1. Navigate to Stack Management.
2. Go to Index Patterns.
3. Click Create index pattern.
4. Enter the pattern name: `honeypot-logs-*`
5. Select `@timestamp` as the Time Filter field.
6. Click Create index pattern.

**Validation:** Check the Discover tab in Kibana to confirm the visibility of all log entries, verifying the entire system is fully operational.

