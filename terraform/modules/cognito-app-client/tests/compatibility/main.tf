terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.38.0"
    }
  }
}

module "legacy_caller" {
  source = "../.."

  app_name     = "compatibility-test"
  environment  = "test"
  user_pool_id = "us-east-1_EXAMPLE"
}
