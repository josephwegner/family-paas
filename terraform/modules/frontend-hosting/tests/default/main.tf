terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region                      = "us-east-1"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
}

module "frontend" {
  source = "../.."

  app_name             = "test-app"
  environment          = "test"
  api_gateway_endpoint = "https://example.execute-api.us-east-1.amazonaws.com"
}
