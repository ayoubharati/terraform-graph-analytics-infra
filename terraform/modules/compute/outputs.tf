output "zeppelin_instance_id" {
  description = "Zeppelin EC2 instance ID"
  value       = aws_instance.zeppelin.id
}

output "zeppelin_private_ip" {
  description = "Zeppelin private IP address"
  value       = aws_instance.zeppelin.private_ip
}

output "zeppelin_public_ip" {
  description = "Zeppelin public IP address"
  value       = aws_instance.zeppelin.public_ip
}

output "spark_instance_id" {
  description = "Spark worker EC2 instance ID"
  value       = aws_instance.spark.id
}

output "spark_private_ip" {
  description = "Spark worker private IP address"
  value       = aws_instance.spark.private_ip
}
