locals {
  metrics_namespace = "${var.project}/${var.environment}"
  alarm_actions     = compact([var.alarm_sns_topic_arn])

  # CloudWatch agent configuration, stored in SSM so it can change without
  # rebuilding instances. The ${aws:...} placeholders are resolved by the agent.
  cloudwatch_agent_config = {
    agent = {
      metrics_collection_interval = 60
    }

    metrics = {
      namespace = local.metrics_namespace

      append_dimensions = {
        AutoScalingGroupName = "$${aws:AutoScalingGroupName}"
        InstanceId           = "$${aws:InstanceId}"
        InstanceType         = "$${aws:InstanceType}"
      }

      # Also publish fleet-wide series keyed only by ASG name, for alarms.
      aggregation_dimensions = [["AutoScalingGroupName"]]

      metrics_collected = {
        mem = {
          measurement = ["mem_used_percent"]
        }
        disk = {
          measurement = ["used_percent"]
          resources   = ["/"]
        }
      }
    }

    logs = {
      logs_collected = {
        files = {
          collect_list = [
            {
              file_path       = "/var/log/app/app.log"
              log_group_name  = aws_cloudwatch_log_group.app.name
              log_stream_name = "{instance_id}"
            },
            {
              file_path       = "/var/log/cloud-init-output.log"
              log_group_name  = aws_cloudwatch_log_group.bootstrap.name
              log_stream_name = "{instance_id}"
            },
          ]
        }
      }
    }
  }
}

resource "aws_cloudwatch_log_group" "app" {
  name              = "/${var.project}/${var.environment}/app"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_group" "bootstrap" {
  name              = "/${var.project}/${var.environment}/bootstrap"
  retention_in_days = var.log_retention_days
}

# The "AmazonCloudWatch-" prefix matters: CloudWatchAgentServerPolicy only
# grants ssm:GetParameter on parameters with that prefix.
resource "aws_ssm_parameter" "cloudwatch_agent" {
  name        = "AmazonCloudWatch-${local.name}"
  description = "CloudWatch agent configuration for ${local.name} app instances"
  type        = "String"
  value       = jsonencode(local.cloudwatch_agent_config)
}

# --- Alarms ----------------------------------------------------------------

resource "aws_cloudwatch_metric_alarm" "unhealthy_hosts" {
  alarm_name          = "${local.name}-unhealthy-hosts"
  alarm_description   = "At least one target has failed ALB health checks for 3 minutes."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "UnHealthyHostCount"
  statistic           = "Maximum"
  period              = 60
  evaluation_periods  = 3
  threshold           = 0
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "target_5xx" {
  alarm_name          = "${local.name}-target-5xx"
  alarm_description   = "The application returned too many 5xx responses in 5 minutes."
  namespace           = "AWS/ApplicationELB"
  metric_name         = "HTTPCode_Target_5XX_Count"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = var.target_5xx_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"

  dimensions = {
    LoadBalancer = aws_lb.this.arn_suffix
    TargetGroup  = aws_lb_target_group.app.arn_suffix
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}

resource "aws_cloudwatch_metric_alarm" "memory_high" {
  alarm_name          = "${local.name}-memory-high"
  alarm_description   = "Average memory use across the fleet has been high for 10 minutes."
  namespace           = local.metrics_namespace
  metric_name         = "mem_used_percent"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = var.memory_alarm_threshold
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "missing"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.app.name
  }

  alarm_actions = local.alarm_actions
  ok_actions    = local.alarm_actions
}
