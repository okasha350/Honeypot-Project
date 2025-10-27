# Week 5: Log Pipeline Troubleshooting and ELK Stack Finalization

## 🎯 Objective

Resolve critical communication failures in the centralized logging pipeline (**Syslog-ng $\rightarrow$ Logstash**) and successfully finalize the ELK Stack configuration to visualize threat data in Kibana. This phase ensures robust log collection and validation.

## 🏗️ Architecture Flow (Final State)

The log flow is stabilized. Logs are forwarded by Syslog-ng on the **Monitoring VM** to the local Logstash Docker container using the host's actual network IP (`192.168.100.20`), bypassing loopback issues.

| Component | Port Used | IP Target | Status |
|---|---|---|---|
| **Cowrie Honeypot** | **22** (Listened Port) | N/A | **Fixed** (Confirmed port trap) |
| **Syslog-ng (Forwarding)** | **5000** (Outbound) | `192.168.100.20` | **Fixed** (Updated destination IP) |
| **Logstash (Docker)** | **5000** (Inbound) | `0.0.0.0` (Bound internally) | **Working** (Accessible via Host IP) |
| **Kibana Access** | **5602** (Web UI) | `192.168.100.20` | **Finalized** |

---

## Part 1: Initial ELK Stack Installation (Monitoring VM)

These steps cover the necessary installations (which typically occurred before Week 5 but are listed here for completeness).

### 1.1 Install Dependencies and Docker

```bash
# Install required dependencies
sudo apt update
sudo apt install -y curl wget apt-transport-https

# Install Docker
sudo apt install -y docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker $USER
(Note: Log out and log back in to apply Docker group changes)

1.2 Setup ELK Stack (Docker Compose)
Create the docker-compose.yml file to run Elasticsearch, Logstash, and Kibana.

Bash

# Create the Docker Compose file
sudo nano docker-compose.yml
Content for docker-compose.yml

(Since the content of docker-compose.yml was not explicitly provided but implied, a standard structure is used here, ensuring Kibana and Logstash ports are exposed.)

YAML

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
      # Use the actual host IP here for connection (as a general practice)
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
    # Expose port 5602 for web access
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
1.3 Setup Logstash Pipeline Configuration
Create the necessary configuration files for Logstash to listen on TCP port 5000 and output to Elasticsearch.

Bash

# Create directories for Logstash config/pipeline
mkdir -p logstash/pipeline
mkdir -p logstash/config

# Create the main configuration file
sudo nano logstash/pipeline/syslog.conf
Content for logstash/pipeline/syslog.conf

مقتطف الرمز

input {
  tcp {
    port => 5000
    type => "honeypot"
    codec => json_lines
  }
}

filter {
  # Add the timestamp field from the log entry itself
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
  stdout { codec => rubydebug }
}
1.4 Start the ELK Stack
Bash

# Start the entire stack in detached mode
sudo docker-compose up -d
Part 2: Syslog-ng Communication Fix
This section details the critical fix implemented in Week 5 to resolve the log forwarding failure.

2.1 Modify Syslog-ng Configuration File
The destination IP in the forwarding configuration on the Monitoring VM must be explicitly set to its own network IP (192.168.100.20) to reach the Logstash port exposed on the host.

Bash

# Edit the Syslog-ng configuration file responsible for forwarding
sudo nano /etc/syslog-ng/conf.d/honeypot-receive.conf
Code Block for d_logstash Fix (Full Content)

مقتطف الرمز

# Configuration for receiving logs from honeypots and forwarding them to Logstash.

# ... (Previous Source definitions remain here) ...

# =================================================================
# FIX: Destination to Logstash (Using 192.168.100.20 instead of 127.0.0.1)
# =================================================================

# Define the destination (Logstash) using the Monitoring VM's actual IP
destination d_logstash {
    tcp("192.168.100.20" port(5000)
        template("$MSG\n") 
        template-escape(no)
    );
};

# ... (Previous Local Log Definitions remain here) ...

# Log Path: Route logs received from the network to Logstash
log {
    source(s_src);
    destination(d_logstash);
    flags(flow-control);
};
2.2 Restart Syslog-ng Service
Bash

# Restart the service to load the new destination IP
sudo systemctl restart syslog-ng

# Verify the service status
sudo systemctl status syslog-ng
Part 3: Final Validation and Log Generation
3.1 Test Logstash Connection (Monitoring VM)
Final connection test to confirm the fix.

Bash

# Command: Send a manual test message to Logstash via the fixed IP/Port 5000
echo '{"message": "Manual Logstash Connection Test Success", "honeypot_source": "manual_test_week5"}' | nc 192.168.100.20 5000
3.2 Generate Cowrie Logs for Final Flow Check (Attacker/Monitoring VM)
Target the honeypot on its trap port (22) to generate live log data.

Bash

# Command: Execute a simulated SSH attack on the Honeypot VM's listening port (22)
ssh -o StrictHostKeyChecking=no testuser@192.168.100.10
3.3 Kibana Access and Index Creation
With logs flowing, the Kibana interface must be configured.

Access Kibana: Navigate to http://192.168.100.20:5602/

Create Index Pattern (Kibana UI Steps):

Navigate to Stack Management.

Go to Index Patterns.

Click Create index pattern.

Enter the pattern name: honeypot-logs-*

Select @timestamp as the Time Filter field.

Click Create index pattern.