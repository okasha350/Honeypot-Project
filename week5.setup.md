# Week 5: Log Pipeline Troubleshooting and ELK Stack Finalization

## 🎯 Objective
Resolve critical communication failures in the centralized logging pipeline (**Syslog-ng → Logstash**) and successfully finalize the ELK Stack configuration to visualize threat data in Kibana. This phase ensures robust log collection and validation.

---

## 🏗️ Architecture Flow (Final State)
The log flow is stabilized. Logs are forwarded by Syslog-ng on the **Monitoring VM** to the local Logstash Docker container using the host's actual network IP (`192.168.100.20`), bypassing loopback issues.

| Component | Port Used | IP Target | Status |
|---|---|---|---|
| **Cowrie Honeypot** | 22 (Listening Port) | N/A | **Fixed** (Confirmed port trap) |
| **Syslog-ng (Forwarding)** | 5000 (Outbound) | `192.168.100.20` | **Fixed** (Updated destination IP) |
| **Logstash (Docker)** | 5000 (Inbound) | 0.0.0.0 (Bound internally) | **Working** (Accessible via Host IP) |
| **Kibana Access** | 5602 (Web UI) | `192.168.100.20` | **Finalized** |

---

## Part 1: Initial ELK Stack Installation (Monitoring VM)

### 1.1 Install Dependencies and Docker
```bash
# Update system and install dependencies
sudo apt update
sudo apt install -y curl wget apt-transport-https

# Install Docker & Docker Compose
sudo apt install -y docker.io docker-compose
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to Docker group
sudo usermod -aG docker $USER
# Note: Log out and log back in to apply Docker group changes
1.2 Setup ELK Stack (Docker Compose)
bash
Copy code
# Create the Docker Compose file
sudo nano docker-compose.yml
yaml
Copy code
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
bash
Copy code
# Create directories for Logstash config/pipeline
mkdir -p logstash/pipeline
mkdir -p logstash/config

# Create the main Logstash pipeline configuration
sudo nano logstash/pipeline/syslog.conf
text
Copy code
input {
  tcp {
    port => 5000
    type => "honeypot"
    codec => json_lines
  }
}

filter {
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
bash
Copy code
# Start ELK Stack in detached mode
sudo docker-compose up -d
Part 2: Syslog-ng Communication Fix
2.1 Modify Syslog-ng Configuration File
bash
Copy code
sudo nano /etc/syslog-ng/conf.d/honeypot-receive.conf
text
Copy code
# Configuration for receiving logs from honeypots and forwarding to Logstash.

# =================================================================
# FIX: Destination to Logstash (Using 192.168.100.20 instead of 127.0.0.1)
# =================================================================
destination d_logstash {
    tcp("192.168.100.20" port(5000)
        template("$MSG\n") 
        template-escape(no)
    );
};

# Log Path: Route logs received from the network to Logstash
log {
    source(s_src);
    destination(d_logstash);
    flags(flow-control);
};
2.2 Restart Syslog-ng Service
bash
Copy code
sudo systemctl restart syslog-ng
sudo systemctl status syslog-ng
Part 3: Final Validation and Log Generation
3.1 Test Logstash Connection
bash
Copy code
echo '{"message": "Manual Logstash Connection Test Success", "honeypot_source": "manual_test_week5"}' | nc 192.168.100.20 5000
3.2 Generate Cowrie Logs for Final Flow Check
bash
Copy code
ssh -o StrictHostKeyChecking=no testuser@192.168.100.10
3.3 Kibana Access and Index Creation
Access Kibana: http://192.168.100.20:5602/

Create Index Pattern (Kibana UI Steps):

Navigate to Stack Management → Index Patterns

Click Create index pattern

Enter pattern name: honeypot-logs-*

Select @timestamp as Time Filter field

Click Create index pattern