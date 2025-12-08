output "bucket_name" {
  description = "S3 bucket name for datasets"
  value       = aws_s3_bucket.datasets.id
}

output "bucket_arn" {
  description = "S3 bucket ARN"
  value       = aws_s3_bucket.datasets.arn
}

output "vpc_endpoint_id" {
  description = "S3 VPC Endpoint ID"
  value       = aws_vpc_endpoint.s3.id
}
