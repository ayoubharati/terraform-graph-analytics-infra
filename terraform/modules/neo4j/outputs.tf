output "instance_id" {
  description = "Neo4j EC2 instance ID"
  value       = aws_instance.neo4j.id
}

output "private_ip" {
  description = "Neo4j private IP address"
  value       = aws_instance.neo4j.private_ip
}
