variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "hajar-project"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.10.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet 1"
  type        = string
  default     = "10.10.1.0/24"
}

variable "public_subnet_2_cidr" {
  description = "CIDR block for public subnet 2"
  type        = string
  default     = "10.10.2.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
  default     = "10.10.11.0/24"
}

variable "availability_zone" {
  description = "Availability zone for subnets 1"
  type        = string
  default     = "eu-central-1a"
}

variable "availability_zone_2" {
  description = "Availability zone for subnets 2"
  type        = string
  default     = "eu-central-1b"
}

variable "zeppelin_instance_type" {
  description = "Instance type for Zeppelin"
  type        = string
  default     = "t3.small"
}

variable "spark_instance_type" {
  description = "Instance type for Spark worker"
  type        = string
  default     = "m7i-flex.large"
}

variable "neo4j_instance_type" {
  description = "Instance type for Neo4j"
  type        = string
  default     = "m7i-flex.large"
}

variable "zeppelin_volume_size" {
  description = "EBS volume size for Zeppelin (GB)"
  type        = number
  default     = 20
}

variable "spark_volume_size" {
  description = "EBS volume size for Spark worker (GB) - minimal for OS + temp"
  type        = number
  default     = 20
}

variable "neo4j_volume_size" {
  description = "EBS volume size for Neo4j (GB) - minimal for graph storage"
  type        = number
  default     = 30
}

variable "ami_id" {
  description = "Ubuntu 22.04 AMI ID for eu-central-1"
  type        = string
  default     = "ami-0084a47cc718c111a" # Ubuntu 22.04 LTS
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for ALB HTTPS (optional, leave empty for HTTP)"
  type        = string
  default     = ""
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed to access ALB"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
