data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "terraform-state-743837809639"
    key    = "shared/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  lambda_bucket = data.terraform_remote_state.shared.outputs.lambda_deployments_bucket
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "lambda_role" {
  name = "${var.app_name}-lambda-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })

  tags = {
    Name        = "${var.app_name}-lambda-role"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

module "lambdas" {
  source   = "git::https://github.com/josephwegner/family-paas.git//terraform/modules/lambda-function?ref=main"
  for_each = {
    "example" = { s3_key = "${var.app_name}/${var.environment}/example.zip" }
  }

  function_name         = each.key
  app_name              = var.app_name
  environment           = var.environment
  lambda_role_arn       = aws_iam_role.lambda_role.arn
  s3_bucket             = local.lambda_bucket
  s3_key                = each.value.s3_key
}

## Uncomment to enable Cognito auth:
# module "auth" {
#   source       = "git::https://github.com/josephwegner/family-paas.git//terraform/modules/cognito-app-client?ref=main"
#   app_name     = var.app_name
#   environment  = var.environment
#   user_pool_id = data.terraform_remote_state.shared.outputs.cognito_user_pool_id
# }

module "api" {
  source      = "git::https://github.com/josephwegner/family-paas.git//terraform/modules/api-gateway?ref=main"
  app_name    = var.app_name
  environment = var.environment

  ## Uncomment to enable JWT auth (requires the auth module above):
  # auth = {
  #   issuer   = data.terraform_remote_state.shared.outputs.cognito_user_pool_issuer
  #   audience = [module.auth.client_id]
  # }

  routes = [
    { route_key = "GET /api/example", function_arn = module.lambdas["example"].invoke_arn, function_name = module.lambdas["example"].function_name },
    ## Example authenticated route:
    # { route_key = "POST /api/protected", function_arn = module.lambdas["protected"].invoke_arn, function_name = module.lambdas["protected"].function_name, auth_required = true },
  ]
}

module "frontend" {
  source               = "git::https://github.com/josephwegner/family-paas.git//terraform/modules/frontend-hosting?ref=main"
  app_name             = var.app_name
  environment          = var.environment
  api_gateway_endpoint = module.api.api_endpoint
}
