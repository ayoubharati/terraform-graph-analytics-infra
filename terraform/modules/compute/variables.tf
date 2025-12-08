variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "ami_id" {
  description = "AMI ID"
  type        = string
}

variable "zeppelin_instance_type" {
  description = "Instance type for Zeppelin"
  type        = string
}

variable "spark_instance_type" {
  description = "Instance type for Spark"
  type        = string
}

variable "zeppelin_volume_size" {
  description = "EBS volume size for Zeppelin"
  type        = number
}

variable "spark_volume_size" {
  description = "EBS volume size for Spark"
  type        = number
}

variable "public_subnet_id" {
  description = "Public subnet ID"
  type        = string
}

variable "private_subnet_id" {
  description = "Private subnet ID"
  type        = string
}

variable "zeppelin_sg_id" {
  description = "Zeppelin security group ID"
  type        = string
}

variable "spark_sg_id" {
  description = "Spark security group ID"
  type        = string
}

variable "iam_instance_profile" {
  description = "IAM instance profile name"
  type        = string
}

variable "key_name" {
  description = "SSH key pair name"
  type        = string
}
