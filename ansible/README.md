# Ansible - Graph Analytics Infrastructure

This Ansible project configures the EC2 instances for the Graph Analytics platform.

## 📁 Directory Structure

```
ansible/
├── ansible.cfg              # Ansible configuration
├── inventory/
│   ├── aws_ec2.yml          # Dynamic inventory (AUTO-DISCOVERS IPs!)
│   └── hosts.yml            # Static inventory (fallback only)
├── playbooks/
│   ├── site.yml             # Master playbook (runs all)
│   ├── common.yml           # Base setup (all instances)
│   ├── zeppelin.yml         # Apache Zeppelin
│   ├── spark.yml            # Apache Spark + GraphX
│   ├── neo4j.yml            # Neo4j Community
│   └── test-connectivity.yml # Connectivity tests
├── roles/
│   ├── zeppelin/templates/  # Zeppelin config templates
│   ├── spark/templates/     # Spark config templates
│   └── neo4j/templates/     # Neo4j config templates
├── variables/
│   ├── main.yml             # Global variables
│   └── secrets.yml          # YOUR SECRETS (create this, gitignored!)
├── scripts/
│   └── connectivity_test.py # Auto-discovers IPs from AWS!
└── logs/                    # Ansible logs
```

> **🔄 Dynamic Discovery**: IPs are discovered automatically from AWS - no manual updates needed!

## 🚀 Quick Start

### Prerequisites

1. **Install Ansible**
   ```bash
   # macOS/Linux
   pip3 install ansible boto3 botocore
   
   # Windows (use WSL)
   sudo apt update && sudo apt install ansible python3-pip
   pip3 install boto3 botocore
   ```

2. **Install AWS EC2 Plugin**
   ```bash
   ansible-galaxy collection install amazon.aws
   ```

3. **Configure AWS Credentials**
   ```bash
   aws configure
   # Or export:
   export AWS_ACCESS_KEY_ID=xxx
   export AWS_SECRET_ACCESS_KEY=xxx
   export AWS_DEFAULT_REGION=eu-central-1
   ```

4. **Configure SSH Key**
   - Place your EC2 key at `~/.ssh/hajar-project-key.pem`
   - Or update `ansible.cfg` with your key path

### Running Playbooks

```bash
cd ansible

# Test connectivity to instances
ansible all -m ping

# Run complete setup
ansible-playbook playbooks/site.yml

# Run specific component
ansible-playbook playbooks/zeppelin.yml
ansible-playbook playbooks/spark.yml
ansible-playbook playbooks/neo4j.yml

# Run only common setup
ansible-playbook playbooks/common.yml

# Run connectivity tests
ansible-playbook playbooks/test-connectivity.yml
```

## 🔐 Secrets Management

**⚠️ IMPORTANT:** Never commit `secrets.yml` to git!

```bash
# 1. Create your secrets file from the template
cp variables/secrets.yml.example variables/secrets.yml

# 2. Edit with your real passwords
nano variables/secrets.yml

# 3. (Optional) Encrypt with Ansible Vault
ansible-vault encrypt variables/secrets.yml

# 4. Run playbooks (with vault password if encrypted)
ansible-playbook playbooks/site.yml --ask-vault-pass
```

## 📋 What Gets Installed

### Common (All Instances)
- Java 11 OpenJDK
- Python 3 + pip
- AWS CLI
- Base packages (curl, wget, git, vim, htop, etc.)
- System tuning (file limits, swap)

### Zeppelin Instance
- Apache Zeppelin 0.10.1
- Scala
- PySpark
- Neo4j Python driver
- Data science packages (pandas, numpy, matplotlib, networkx)

### Spark Instance
- Apache Spark 3.5.0
- GraphX (included)
- AWS Hadoop libraries (S3 access)
- Neo4j Spark Connector

### Neo4j Instance
- Neo4j Community 5.15.0
- APOC plugin
- Automated backup to S3

## 🧪 Testing

### Connectivity Tests

Run the test script on each instance:

```bash
# From local machine (external tests only)
python3 scripts/connectivity_test.py

# Via Ansible (on all instances)
ansible-playbook playbooks/test-connectivity.yml
```

### Service Health Checks

```bash
# Check Zeppelin
curl http://<alb-dns>:8080

# Check Spark Master Web UI
curl http://<spark-ip>:8081

# Check Neo4j
curl http://<neo4j-ip>:7474
```

## 🔧 Configuration

Update `variables/main.yml` for customization:

| Variable | Default | Description |
|----------|---------|-------------|
| `spark_version` | 3.5.0 | Spark version |
| `zeppelin_version` | 0.10.1 | Zeppelin version |
| `neo4j_version` | 5.15.0 | Neo4j version |
| `spark_worker_memory` | 4g | Spark worker memory |
| `neo4j_heap_max_size` | 2g | Neo4j max heap |

## 📊 Post-Installation

After running the playbooks:

1. **Access Zeppelin** via ALB URL
2. **Create a notebook** and connect to Spark
3. **Test Neo4j** connection from Zeppelin
4. **Upload datasets** to S3
5. **Run graph analytics**!

## 🐛 Troubleshooting

### Cannot connect to instances
```bash
# Check if instances are running
aws ec2 describe-instances --filters "Name=tag:Name,Values=hajar-project-*" --query 'Reservations[*].Instances[*].[InstanceId,State.Name,PrivateIpAddress]' --output table

# Test SSH directly
ssh -i ~/.ssh/hajar-project-key.pem ubuntu@<ip>
```

### Ansible hangs on "Gathering Facts"
- Check security groups allow SSH (port 22)
- Verify the SSH key is correct

### Services not starting
```bash
# Check logs on the instance
sudo journalctl -u zeppelin -f
sudo journalctl -u spark-master -f
sudo journalctl -u neo4j -f
```
