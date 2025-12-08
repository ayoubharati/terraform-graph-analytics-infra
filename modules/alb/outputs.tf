output "alb_dns_name" {
  description = "ALB DNS name for accessing Zeppelin"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ALB ARN"
  value       = aws_lb.main.arn
}

output "alb_zone_id" {
  description = "ALB hosted zone ID"
  value       = aws_lb.main.zone_id
}

output "zeppelin_sg_id" {
  description = "Zeppelin security group ID"
  value       = aws_security_group.zeppelin.id
}

output "alb_sg_id" {
  description = "ALB security group ID"
  value       = aws_security_group.alb.id
}

output "target_group_arn" {
  description = "Target group ARN"
  value       = aws_lb_target_group.zeppelin.arn
}
