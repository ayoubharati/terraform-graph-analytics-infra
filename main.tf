terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Network module
module "network" {
  source = "./modules/network"

  project_name         = var.project_name
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidr   = var.public_subnet_cidr
  private_subnet_cidr  = var.private_subnet_cidr
  availability_zone    = var.availability_zone
}

# S3 module
module "s3" {
  source = "./modules/s3"

  project_name = var.project_name
  vpc_id       = module.network.vpc_id
  route_table_id = module.network.private_route_table_id
}

# IAM module
module "iam" {
  source = "./modules/iam"

  project_name = var.project_name
  s3_bucket_arn = module.s3.bucket_arn
}

# Compute module (Zeppelin + Spark)
module "compute" {
  source = "./modules/compute"

  project_name          = var.project_name
  ami_id                = var.ami_id
  zeppelin_instance_type = var.zeppelin_instance_type
  spark_instance_type   = var.spark_instance_type
  zeppelin_volume_size  = var.zeppelin_volume_size
  spark_volume_size     = var.spark_volume_size
  
  public_subnet_id      = module.network.public_subnet_id
  private_subnet_id     = module.network.private_subnet_id
  
  zeppelin_sg_id        = module.alb.zeppelin_sg_id
  spark_sg_id           = module.network.spark_sg_id
  
  iam_instance_profile  = module.iam.instance_profile_name
}

# Neo4j module
module "neo4j" {
  source = "./modules/neo4j"

  project_name         = var.project_name
  ami_id               = var.ami_id
  instance_type        = var.neo4j_instance_type
  volume_size          = var.neo4j_volume_size
  private_subnet_id    = module.network.private_subnet_id
  security_group_id    = module.network.neo4j_sg_id
  iam_instance_profile = module.iam.instance_profile_name
}

# ALB module
module "alb" {
  source = "./modules/alb"

  project_name          = var.project_name
  vpc_id                = module.network.vpc_id
  public_subnet_id      = module.network.public_subnet_id
  acm_certificate_arn   = var.acm_certificate_arn
  allowed_cidr_blocks   = var.allowed_cidr_blocks
  zeppelin_instance_id  = module.compute.zeppelin_instance_id
}

# Monitoring module
module "monitoring" {
  source = "./modules/monitoring"

  project_name = var.project_name
}
