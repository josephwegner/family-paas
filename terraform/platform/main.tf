data "aws_caller_identity" "current" {}

check "platform_account" {
  assert {
    condition     = data.aws_caller_identity.current.account_id == var.platform_account_id
    error_message = "Refusing to manage platform resources from an unexpected AWS account."
  }
}

resource "aws_s3_bucket" "terraform_state" {
  bucket = var.state_bucket_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

locals {
  tenant_registry = {
    for tenant_id, tenant in var.tenants : tenant_id => {
      workload_account_id    = tenant.workload_account_id
      workload_principal_arn = tenant.workload_principal_arn
      state_prefix           = "tenants/${tenant_id}"
      state_role_name        = "family-paas-${tenant_id}-state"
    }
  }
}

data "aws_iam_policy_document" "tenant_trust" {
  for_each = local.tenant_registry

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [each.value.workload_principal_arn]
    }
  }
}

resource "aws_iam_role" "tenant_state" {
  for_each = local.tenant_registry

  name               = each.value.state_role_name
  assume_role_policy = data.aws_iam_policy_document.tenant_trust[each.key].json
}

data "aws_iam_policy_document" "tenant_state" {
  for_each = local.tenant_registry

  statement {
    sid       = "TenantStateObjects"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.terraform_state.arn}/${each.value.state_prefix}/*"]
  }

  statement {
    sid       = "TenantStatePrefixList"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.terraform_state.arn]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = [each.value.state_prefix, "${each.value.state_prefix}/*"]
    }
  }
}

resource "aws_iam_role_policy" "tenant_state" {
  for_each = local.tenant_registry

  name   = "tenant-state-prefix"
  role   = aws_iam_role.tenant_state[each.key].id
  policy = data.aws_iam_policy_document.tenant_state[each.key].json
}
