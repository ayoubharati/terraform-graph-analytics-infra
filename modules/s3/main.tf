# S3 Bucket for Datasets
resource "aws_s3_bucket" "datasets" {
  bucket = "${var.project_name}-datasets-euc1"

  tags = {
    Name = "${var.project_name}-datasets"
  }
}

# Block public access
resource "aws_s3_bucket_public_access_block" "datasets" {
  bucket = aws_s3_bucket.datasets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning
resource "aws_s3_bucket_versioning" "datasets" {
  bucket = aws_s3_bucket.datasets.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Server-side encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "datasets" {
  bucket = aws_s3_bucket.datasets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 VPC Endpoint (Gateway)
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.eu-central-1.s3"
  
  route_table_ids = [var.route_table_id]

  tags = {
    Name = "${var.project_name}-s3-endpoint"
  }
}
