data "aws_caller_identity" "current" {}

check "workload_account" {
  assert {
    condition     = data.aws_caller_identity.current.account_id == var.workload_account_id
    error_message = "Refusing to bootstrap an unexpected AWS account."
  }
}

resource "aws_s3_bucket" "lambda_deployments" {
  bucket = "lambda-deployments-${var.workload_account_id}"

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "lambda_deployments" {
  bucket = aws_s3_bucket.lambda_deployments.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "lambda_deployments" {
  bucket = aws_s3_bucket.lambda_deployments.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "lambda_deployments" {
  bucket = aws_s3_bucket.lambda_deployments.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
