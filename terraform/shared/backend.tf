terraform {
  backend "s3" {
    bucket         = "terraform-state-743837809639"
    key            = "shared/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}
