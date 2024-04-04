# Target tracking keeps average CPU near the target. Scale-in is slower than
# scale-out by design: AWS only removes capacity once the metric has stayed
# below target for a while.
resource "aws_autoscaling_policy" "cpu" {
  name                   = "${local.name}-cpu-target"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }

    target_value = var.cpu_target_value
  }
}

# Optional second signal for request-bound workloads where CPU lags behind
# traffic. With two policies, the ASG scales out on whichever asks for more.
resource "aws_autoscaling_policy" "alb_requests" {
  count = var.requests_per_target > 0 ? 1 : 0

  name                   = "${local.name}-alb-requests-target"
  autoscaling_group_name = aws_autoscaling_group.app.name
  policy_type            = "TargetTrackingScaling"

  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${aws_lb.this.arn_suffix}/${aws_lb_target_group.app.arn_suffix}"
    }

    target_value = var.requests_per_target
  }
}
