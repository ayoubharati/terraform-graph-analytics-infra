# Graph Analytics Infrastructure on AWS

Production-grade Terraform infrastructure for graph analytics using **Apache Spark GraphX**, **Apache Giraph**, **Neo4j**, and **Apache Zeppelin** on AWS.

## 🏗️ Architecture Overview

### Network Design
- **VPC**: `[VPC_CIDR]` in `eu-central-1`
- **Public Subnet** (`[PUBLIC_SUBNET_CIDR]`): ALB + Zeppelin
- **Private Subnet** (`[PRIVATE_SUBNET_CIDR]`): Spark worker + Neo4j
- **Internet Gateway**: Public internet access
- **NAT Gateway**: Outbound-only for private instances
- **S3 VPC Endpoint**: Free private S3 access (no NAT charges)

### Compute Resources

| Component | Type | Subnet | Disk | Purpose |
|-----------|------|--------|------|---------|
| Zeppelin | t3.small | Public | 20 GB | Notebook UI (via ALB) |
| Spark Worker | m7i-flex.large | Private | 20 GB | GraphX + Giraph processing |
| Neo4j | m7i-flex.large | Private | 30 GB | Graph database |

**Storage Rationale:**
- **20 GB** (Zeppelin/Spark): Minimal for OS + binaries + temp shuffle
- **30 GB** (Neo4j): Minimal for OS + graph store + indexes

### Security Model

```
Internet → ALB (HTTPS) → Zeppelin (public subnet)
                            ↓ (private SG rules)
                         Spark (private) ←→ Neo4j (private)
                            ↓
                         S3 (via VPC endpoint)
```

- **ALB**: Only exposes Zeppelin (port 8080)
- **Private instances**: No public IPs, NAT for outbound only
- **Security Groups**: Restrict all traffic by source/destination
- **IAM**: SSM access (no SSH keys), S3 read/write, CloudWatch logging

## 📦 What Gets Deployed

### AWS Resources
- 1 VPC with 2 subnets (1 public, 1 private)
- 1 Internet Gateway
- 1 NAT Gateway
- 1 S3 VPC Endpoint (Gateway)
- 1 Application Load Balancer (ALB)
- 3 EC2 instances (Zeppelin, Spark, Neo4j) - **bare Ubuntu 22.04**
- 1 S3 bucket (datasets)
- Security Groups (ALB, Zeppelin, Spark, Neo4j)
- IAM roles + policies (SSM, S3, CloudWatch)
- CloudWatch Log Groups
- CloudTrail (audit logging)

### Software Stack
- **Configuration Management**: Use Ansible to install/configure:
  - Apache Zeppelin
  - Apache Spark + GraphX
  - Apache Giraph
  - Neo4j
  - Java, Scala, and dependencies
- **OS**: Ubuntu 22.04 LTS

**Note**: EC2 instances are provisioned with bare Ubuntu. Use Ansible or your preferred configuration management tool to install and configure the graph analytics stack.

## 🚀 Deployment

### Prerequisites
1. **Terraform** >= 1.0
2. **AWS CLI** configured with credentials
3. **IAM permissions** for VPC, EC2, S3, IAM, ALB, CloudWatch

### Steps

1. **Clone and navigate:**
   ```bash
   cd terraform-graph-analytics-infra
   ```

2. **Review variables** (optional):
   Edit `variables.tf` or create `terraform.tfvars` to customize:
   - Region (default: `eu-central-1`)
   - Instance types
   - Disk sizes
   - CIDR blocks

3. **Initialize Terraform:**
   ```bash
   terraform init
   ```

4. **Plan deployment:**
   ```bash
   terraform plan
   ```

5. **Deploy:**
   ```bash
   terraform apply
   ```
   Type `yes` when prompted.

6. **Get outputs:**
   ```bash
   terraform output
   ```

7. **Configure instances:**
   
   Use Ansible or your preferred tool to install:
   - Apache Zeppelin on the Zeppelin instance
   - Apache Spark + GraphX + Giraph on the Spark instance
   - Neo4j on the Neo4j instance
   
   *(Ansible playbooks to be created separately)*

## 📊 Accessing the Stack

### Zeppelin Notebook
After Ansible configuration, access Zeppelin via the ALB:
```
http://<alb-dns-name>
```
Get the DNS name from:
```bash
terraform output alb_dns_name
```

### SSH/SSM Access
Connect to instances using AWS Systems Manager (no SSH keys needed):

```bash
# Zeppelin
aws ssm start-session --target <zeppelin-instance-id> --region eu-central-1

# Spark
aws ssm start-session --target <spark-instance-id> --region eu-central-1

# Neo4j
aws ssm start-session --target <neo4j-instance-id> --region eu-central-1
```

Instance IDs from:
```bash
terraform output ssm_commands
```

### Neo4j Access
Neo4j is **not** publicly accessible. Connect from Zeppelin or Spark:

- **Bolt**: `bolt://<neo4j-private-ip>:7687`
- **HTTP**: `http://<neo4j-private-ip>:7474`

Get Neo4j IP:
```bash
terraform output neo4j_private_ip
```

## 📁 Upload Dataset to S3

Upload the Elliptic dataset (or any graph data):

```bash
# Get bucket name
BUCKET=$(terraform output -raw s3_bucket_name)

# Upload files
aws s3 cp elliptic_dataset/ s3://$BUCKET/elliptic/ --recursive
```

## 🧹 Cleanup

To destroy all resources:

```bash
terraform destroy
```

Type `yes` when prompted. This will:
- Terminate all EC2 instances
- Delete ALB and NAT Gateway
- Remove VPC and subnets
- **⚠️ Delete S3 buckets** (data will be lost!)

## 💰 Cost Estimate (eu-central-1)

**Monthly costs** (approximate):

| Resource | Cost |
|----------|------|
| EC2 (t3.small) | ~$15 |
| EC2 (2x m7i-flex.large) | ~$110 |
| NAT Gateway | ~$32 + data transfer |
| ALB | ~$16 + data transfer |
| EBS (70 GB gp3) | ~$6 |
| S3 storage (minimal) | ~$1 |
| **Total** | **~$180/month** |

**Cost optimization:**
- Use Spot Instances for Spark/Neo4j (-70%)
- Stop instances when not in use
- Remove NAT Gateway (restrict outbound access)

## 🔒 Security Best Practices

### Before Production:
1. **Add ACM certificate** for HTTPS (set `acm_certificate_arn` in `variables.tf`)
2. **Restrict ALB CIDR** (set `allowed_cidr_blocks` to your IP range)
3. **Enable MFA** for AWS account
4. **Review IAM policies** (principle of least privilege)
5. **Enable VPC Flow Logs**
6. **Configure CloudWatch Alarms**

### Network Isolation:
- Private instances have **no public IPs**
- All private traffic enforced by Security Groups
- S3 access via VPC endpoint (no internet routing)
- SSM for access (no SSH keys to manage)

## 📝 Module Structure

```
terraform-graph-analytics-infra/
├── main.tf                      # Root orchestration
├── variables.tf                 # Input variables
├── outputs.tf                   # Output values
├── .gitignore                   # Terraform gitignore
├── modules/
│   ├── network/                 # VPC, subnets, routing, SGs
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── s3/                      # S3 bucket + VPC endpoint
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── iam/                     # Roles, policies, profiles
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── compute/                 # Zeppelin + Spark EC2
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── neo4j/                   # Neo4j EC2
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── alb/                     # Application Load Balancer
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── monitoring/              # CloudWatch + CloudTrail
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
└── env/                         # Environment-specific tfvars
    └── dev.tfvars
```

## 🐛 Troubleshooting

### Zeppelin not accessible
- Ensure Zeppelin is installed and running (via Ansible)
- Check ALB health checks: `aws elbv2 describe-target-health --target-group-arn <tg-arn>`
- Verify Security Group rules allow ALB → Zeppelin on port 8080

### Spark can't read S3
- Confirm IAM role attached to instance
- Check S3 VPC endpoint route table association
- Verify bucket region matches VPC region

### Neo4j connection refused
- Ensure Neo4j is installed and running (via Ansible)
- Verify Spark/Zeppelin use private IP (not public)
- Check Security Group allows port 7687 from source SG
- Confirm Neo4j service is running: `systemctl status neo4j`

### SSM session fails
- Confirm IAM instance profile has `AmazonSSMManagedInstanceCore`
- Check instance has internet access (via NAT or IGW)
- Verify SSM agent is running

---

**Built with Terraform** | **Configure with Ansible**