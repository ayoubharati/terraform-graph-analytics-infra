# Zeppelin EC2 Instance
resource "aws_instance" "zeppelin" {
  ami                    = var.ami_id
  instance_type          = var.zeppelin_instance_type
  subnet_id              = var.public_subnet_id
  vpc_security_group_ids = [var.zeppelin_sg_id]
  iam_instance_profile   = var.iam_instance_profile
  key_name               = var.key_name

  root_block_device {
    volume_type = "gp3"
    volume_size = var.zeppelin_volume_size
    encrypted   = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-zeppelin"
  }
}

# Spark Worker EC2 Instance
resource "aws_instance" "spark" {
  ami                    = var.ami_id
  instance_type          = var.spark_instance_type
  subnet_id              = var.private_subnet_id
  vpc_security_group_ids = [var.spark_sg_id]
  iam_instance_profile   = var.iam_instance_profile
  key_name               = var.key_name

  root_block_device {
    volume_type = "gp3"
    volume_size = var.spark_volume_size
    encrypted   = true
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  tags = {
    Name = "${var.project_name}-spark-worker"
  }
}
