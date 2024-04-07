resource "aws_launch_template" "app" {
  name_prefix            = "${local.name}-app-"
  description            = "Application instances for ${local.name}"
  image_id               = local.ami_id
  instance_type          = local.instance_type
  key_name               = var.ssh_key_name
  vpc_security_group_ids = [aws_security_group.app.id]
  update_default_version = true

  user_data = base64encode(templatefile("${path.module}/templates/user_data.sh.tftpl", {
    region                      = var.region
    app_port                    = var.app_port
    artifact_bucket             = aws_s3_bucket.artifacts.id
    version_parameter           = aws_ssm_parameter.app_version.name
    cloudwatch_config_parameter = aws_ssm_parameter.cloudwatch_agent.name
  }))

  iam_instance_profile {
    arn = aws_iam_instance_profile.app.arn
  }

  # IMDSv2 only.
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring {
    enabled = var.detailed_monitoring
  }

  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_size           = var.root_volume_size
      volume_type           = "gp3"
      encrypted             = true
      delete_on_termination = true
    }
  }

  tag_specifications {
    resource_type = "volume"
    tags          = merge(local.common_tags, { Name = "${local.name}-app" })
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app" {
  name_prefix         = "${local.name}-app-"
  min_size            = var.asg_min_size
  max_size            = var.asg_max_size
  desired_capacity    = var.asg_desired_capacity
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns   = [aws_lb_target_group.app.arn]

  # Replace instances that fail the ALB health check, not just EC2 status checks.
  # The grace period covers bootstrap, including waiting for a first release.
  health_check_type         = "ELB"
  health_check_grace_period = 300
  default_instance_warmup   = 120

  launch_template {
    id      = aws_launch_template.app.id
    version = aws_launch_template.app.latest_version
  }

  # A new launch template version rolls the fleet, keeping half of it in service.
  instance_refresh {
    strategy = "Rolling"

    preferences {
      min_healthy_percentage = 50
    }
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMinSize",
    "GroupMaxSize",
    "GroupPendingInstances",
    "GroupTerminatingInstances",
  ]

  # default_tags don't reach instances launched by an ASG, so propagate them here.
  dynamic "tag" {
    for_each = merge(local.common_tags, { Name = "${local.name}-app", Role = "app" })

    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
    # Scaling policies own desired capacity once the group exists.
    ignore_changes = [desired_capacity]
  }
}
