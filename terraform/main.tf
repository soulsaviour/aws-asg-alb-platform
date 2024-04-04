locals {
  name = "${var.project}-${var.environment}"

  common_tags = merge(
    {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    },
    var.tags,
  )
}

data "aws_partition" "current" {}

# Latest Amazon Linux 2023 AMI for the chosen architecture, unless one is pinned.
data "aws_ami" "al2023" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-kernel-*-${var.architecture}"]
  }

  filter {
    name   = "architecture"
    values = [var.architecture]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  ami_id        = coalesce(var.ami_id, data.aws_ami.al2023.id)
  instance_type = coalesce(var.instance_type, var.architecture == "arm64" ? "t4g.small" : "t3.small")
}
