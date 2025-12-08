output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = aws_subnet.private.id
}

output "private_route_table_id" {
  description = "Private route table ID for VPC endpoints"
  value       = aws_route_table.private.id
}

output "spark_sg_id" {
  description = "Spark security group ID"
  value       = aws_security_group.spark.id
}

output "neo4j_sg_id" {
  description = "Neo4j security group ID"
  value       = aws_security_group.neo4j.id
}

output "nat_gateway_id" {
  description = "NAT Gateway ID"
  value       = aws_nat_gateway.main.id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}
