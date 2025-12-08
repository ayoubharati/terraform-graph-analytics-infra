variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnet_1_id" {
  description = "Public subnet 1 ID"
  type        = string
}

variable "public_subnet_2_id" {
  description = "Public subnet 2 ID"
  type        = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS"
  type        = string
}

variable "allowed_cidr_blocks" {
  description = "Allowed CIDR blocks for ALB access"
  type        = list(string)
}

variable "zeppelin_instance_id" {
  description = "Zeppelin instance ID for target group"
  type        = string
}
