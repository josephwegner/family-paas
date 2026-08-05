terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
}

resource "aws_s3_bucket" "lambda_deployments" {
  bucket = "lambda-deployments-${local.account_id}"

  tags = {
    Name        = "Lambda Deployments"
    Environment = "shared"
    ManagedBy   = "terraform"
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

resource "aws_s3_bucket" "shared_media" {
  bucket = "shared-media-${local.account_id}"

  tags = {
    Name        = "Shared Media"
    Environment = "shared"
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "shared_media" {
  bucket = aws_s3_bucket.shared_media.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "shared_data" {
  name         = "shared-app-data"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "pk"
  range_key    = "sk"

  attribute {
    name = "pk"
    type = "S"
  }

  attribute {
    name = "sk"
    type = "S"
  }

  tags = {
    Name        = "Shared App Data"
    Environment = "shared"
    ManagedBy   = "terraform"
  }
}

resource "aws_cognito_user_pool" "family" {
  name = "family-paas-users"

  # Username-based sign-in (immutable, globally unique, case-insensitive)
  # rather than email-as-username. Email/phone remain optional attributes,
  # not required and not used as sign-in aliases.
  username_configuration {
    case_sensitive = false
  }

  # Default Cognito password policy and throttling — no adaptive-security or
  # bespoke lockout system.
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = true
  }

  schema {
    name                = "email"
    attribute_data_type = "String"
    required            = false
    mutable             = true
  }

  schema {
    name                = "phone_number"
    attribute_data_type = "String"
    required            = false
    mutable             = true
  }

  # Self-registration (sign-up) stays enabled at the Cognito layer; it only
  # creates an unattached identity. Any app-specific server-validated
  # onboarding flow is enforced at the application layer, not here.
  admin_create_user_config {
    allow_admin_create_user_only = false
  }

  # Reviewed safeguard against accidental deletion once real users exist.
  deletion_protection = "ACTIVE"

  tags = {
    Name        = "Family PaaS Users"
    Environment = "shared"
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_account_password_policy" "strict" {
  minimum_password_length        = 14
  require_lowercase_characters   = true
  require_uppercase_characters   = true
  require_numbers                = true
  require_symbols                = true
  allow_users_to_change_password = true
  max_password_age               = 90
  password_reuse_prevention      = 5
}
