# Releases are immutable tarballs in S3 (releases/app-<version>.tar.gz). An SSM
# parameter says which one is current, so instances launched by scaling or an
# instance refresh always boot the release that's live, not whatever was baked
# into the launch template.

resource "aws_s3_bucket" "artifacts" {
  bucket_prefix = "${local.name}-artifacts-"
  force_destroy = var.environment != "prod"
}

resource "aws_s3_bucket_public_access_block" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "artifacts" {
  bucket = aws_s3_bucket.artifacts.id

  rule {
    id     = "expire-noncurrent-versions"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_ssm_parameter" "app_version" {
  name        = "/${var.project}/${var.environment}/app/current-version"
  description = "Release that ${local.name} instances run. Moved by the deploy playbook."
  type        = "String"
  value       = var.initial_release_version

  lifecycle {
    # Deployments move this pointer; Terraform only sets the starting value.
    ignore_changes = [value]
  }
}
