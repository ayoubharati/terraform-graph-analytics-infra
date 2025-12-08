output "vpc_id" {
  description = "VPC ID"
  value       = module.network.vpc_id
}

output "alb_dns_name" {
  description = "ALB DNS name for accessing Zeppelin"
  value       = module.alb.alb_dns_name
}

output "s3_bucket_name" {
  description = "S3 bucket name for datasets"
  value       = module.s3.bucket_name
}

output "zeppelin_instance_id" {
  description = "Zeppelin EC2 instance ID"
  value       = module.compute.zeppelin_instance_id
}

output "spark_instance_id" {
  description = "Spark worker EC2 instance ID"
  value       = module.compute.spark_instance_id
}

output "neo4j_instance_id" {
  description = "Neo4j EC2 instance ID"
  value       = module.neo4j.instance_id
}

output "neo4j_private_ip" {
  description = "Neo4j private IP address"
  value       = module.neo4j.private_ip
}

output "ssm_commands" {
  description = "AWS SSM commands to connect to instances"
  value = {
    zeppelin = "aws ssm start-session --target ${module.compute.zeppelin_instance_id} --region ${var.aws_region}"
    spark    = "aws ssm start-session --target ${module.compute.spark_instance_id} --region ${var.aws_region}"
    neo4j    = "aws ssm start-session --target ${module.neo4j.instance_id} --region ${var.aws_region}"
  }
}
