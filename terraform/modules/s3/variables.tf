variable "project_name" {
  description = "Project name prefix"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "route_table_id" {
  description = "Private route table ID for VPC endpoint"
  type        = string
}
