data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app" {
  name_prefix        = "${local.name}-app-"
  description        = "Role for ${local.name} application instances"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# Session Manager access instead of opening SSH to the world.
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.app.name
  policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "app" {
  name_prefix = "${local.name}-app-"
  role        = aws_iam_role.app.name
}
