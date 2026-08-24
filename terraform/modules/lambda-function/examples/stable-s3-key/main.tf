terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

# This fixture intentionally keeps s3_key constant. Set source_code_hash to the
# base64-encoded raw SHA-256 of the ZIP currently stored at that key.
module "lambda" {
  source = "../.."

  function_name    = var.function_name
  app_name         = var.app_name
  environment      = var.environment
  lambda_role_arn  = var.lambda_role_arn
  s3_bucket        = var.s3_bucket
  s3_key           = var.s3_key
  source_code_hash = var.source_code_hash
}
