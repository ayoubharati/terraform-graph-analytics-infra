# Ansible - Graph Analytics Infrastructure

This Ansible project configures the EC2 instances for the Graph Analytics platform.

## 📁 Directory Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── run.sh                   # Easy runner script (use from WSL)
├── inventory/
│   ├── aws_ec2.yml          # Dynamic inventory (AUTO-DISCOVERS IPs!)
│   └── hosts.yml            # Static inventory (fallback)
├── playbooks/
│   ├── site.yml             # Master playbook (runs all 4)
│   ├── zeppelin.yml         # Zeppelin + Spark client + Data prep
│   ├── spark.yml            # Spark Master/Worker + GraphX
│   ├── giraph.yml           # Hadoop (HDFS/YARN) + Giraph
│   └── neo4j.yml            # Neo4j + APOC + Data import
├── roles/
│   ├── zeppelin/templates/  # Zeppelin config templates
│   ├── spark/templates/     # Spark config templates
│   ├── giraph/templates/    # Hadoop/Giraph config templates
│   └── neo4j/templates/     # Neo4j config templates
├── variables/
│   ├── main.yml             # Global variables
│   └── secrets.yml          # YOUR SECRETS (create this, gitignored!)
└── logs/                    # Ansible logs
```

## 🚀 Quick Start

### Prerequisites

1. **Install Ansible (in WSL)**
   ```bash
   sudo apt update && sudo apt install ansible python3-pip
   pip3 install boto3 botocore
   ansible-galaxy collection install amazon.aws
   ```

2. **Configure AWS Credentials**
   ```bash
   aws configure
   ```

3. **Create secrets.yml**
   ```bash
   cp variables/secrets.yml.template variables/secrets.yml
   nano variables/secrets.yml
   ```

### Running Playbooks

```bash
cd ansible

# Run ALL playbooks (complete setup)
./run.sh playbooks/site.yml

# Run individual playbooks
./run.sh playbooks/zeppelin.yml    # Zeppelin + Spark client
./run.sh playbooks/spark.yml       # Spark Master/Worker
./run.sh playbooks/giraph.yml      # Hadoop + Giraph
./run.sh playbooks/neo4j.yml       # Neo4j database

# Optional: Download dataset (after zeppelin.yml)
./run.sh playbooks/zeppelin.yml --tags data

# Optional: Import dataset to Neo4j (after neo4j.yml and data)
./run.sh playbooks/neo4j.yml --tags import
```

## 📋 What Each Playbook Installs

### 1. zeppelin.yml (Analytics Hub)
- ✅ Common packages + Java 11
- ✅ Apache Zeppelin 0.11.2
- ✅ Apache Spark client (for driver)
- ✅ Python packages (neo4j, pandas, numpy, matplotlib, networkx)
- ✅ Data download from Kaggle (optional --tags data)

### 2. spark.yml (Compute Cluster)
- ✅ Common packages + Java 11
- ✅ Apache Spark 3.5.0 Master + Worker
- ✅ GraphX (included in Spark)
- ✅ AWS S3 libraries

### 3. giraph.yml (Graph Processing)
- ✅ Apache Hadoop 3.3.6 (HDFS + YARN)
- ✅ Apache Giraph 1.2.0
- ✅ Sample graph data + PageRank script

### 4. neo4j.yml (Graph Database)
- ✅ Common packages + Java 17
- ✅ Neo4j Community 5.x
- ✅ APOC plugin
- ✅ Data import from S3 (optional --tags import)

## 🔐 Secrets Management

**⚠️ IMPORTANT:** Never commit `secrets.yml` to git!

```yaml
# variables/secrets.yml
---
neo4j_admin_password: "your-secure-password"
kaggle_api_token: "your-kaggle-token"
```

## 🧪 Recommended Run Order

For a fresh deployment:

```bash
# 1. Run all base playbooks
./run.sh playbooks/site.yml

# 2. Download dataset
./run.sh playbooks/zeppelin.yml --tags data

# 3. Import to Neo4j
./run.sh playbooks/neo4j.yml --tags import

# 4. Open Zeppelin and test!
# http://<zeppelin-public-ip>:8080
```

## 📊 Service URLs (After Deployment)

| Service | URL | Notes |
|---------|-----|-------|
| Zeppelin | http://\<zeppelin-ip\>:8080 | Public access |
| Spark Master UI | http://\<spark-ip\>:8081 | Internal only |
| HDFS NameNode UI | http://\<spark-ip\>:9870 | Internal only |
| YARN ResourceManager | http://\<spark-ip\>:8088 | Internal only |
| Neo4j Browser | http://\<neo4j-ip\>:7474 | Internal only |
| Neo4j Bolt | bolt://\<neo4j-ip\>:7687 | Internal only |

## 🐛 Troubleshooting

### Timeout errors
All large downloads use `async` - just wait or re-run the playbook.

### SSH issues
```bash
# Test SSH directly
ssh -i ~/hajar-project-key.pem ubuntu@<ip>
```

### Service not starting
```bash
# Check logs on the instance
sudo journalctl -u zeppelin -f
sudo journalctl -u spark-master -f
sudo journalctl -u neo4j -f
```

### Neo4j Spark Connector version mismatch
The connector is loaded via `--packages` in Zeppelin to ensure version consistency. Do NOT install it manually on the Spark server.
