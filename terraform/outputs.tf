output "region" {
  description = "Region the stack is deployed in."
  value       = var.region
}

output "alb_dns_name" {
  description = "Public DNS name of the load balancer."
  value       = aws_lb.this.dns_name
}

output "app_url" {
  description = "URL of the application."
  value       = "${local.https_enabled ? "https" : "http"}://${aws_lb.this.dns_name}"
}

output "target_group_arn" {
  description = "ARN of the application target group."
  value       = aws_lb_target_group.app.arn
}

output "asg_name" {
  description = "Name of the Auto Scaling group."
  value       = aws_autoscaling_group.app.name
}

output "launch_template_id" {
  description = "ID of the launch template."
  value       = aws_launch_template.app.id
}

output "app_log_group" {
  description = "CloudWatch log group for application logs."
  value       = aws_cloudwatch_log_group.app.name
}

output "cloudwatch_agent_config_parameter" {
  description = "SSM parameter holding the CloudWatch agent configuration."
  value       = aws_ssm_parameter.cloudwatch_agent.name
}

output "artifact_bucket" {
  description = "S3 bucket that holds release tarballs."
  value       = aws_s3_bucket.artifacts.id
}

output "version_parameter" {
  description = "SSM parameter pointing at the current release."
  value       = aws_ssm_parameter.app_version.name
}
