# Load balancer: accepts HTTP(S) from the allowed networks and only talks to the
# application instances on the app port.

resource "aws_security_group" "alb" {
  name_prefix = "${local.name}-alb-"
  description = "Ingress to the application load balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name}-alb"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  for_each = toset(var.allowed_ingress_cidrs)

  security_group_id = aws_security_group.alb.id
  description       = "HTTP from ${each.value}"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  for_each = local.https_enabled ? toset(var.allowed_ingress_cidrs) : toset([])

  security_group_id = aws_security_group.alb.id
  description       = "HTTPS from ${each.value}"
  cidr_ipv4         = each.value
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "alb_to_app" {
  security_group_id            = aws_security_group.alb.id
  description                  = "Forward requests to the application instances"
  referenced_security_group_id = aws_security_group.app.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

# Application instances: only reachable from the load balancer.

resource "aws_security_group" "app" {
  name_prefix = "${local.name}-app-"
  description = "Application instances behind the load balancer"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${local.name}-app"
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_alb" {
  security_group_id            = aws_security_group.app.id
  description                  = "Requests from the load balancer"
  referenced_security_group_id = aws_security_group.alb.id
  ip_protocol                  = "tcp"
  from_port                    = var.app_port
  to_port                      = var.app_port
}

resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id
  description       = "Outbound for package installs, SSM and CloudWatch"
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
