locals {
  lambda_bucket = "lambda-deployments-${var.workload_account_id}"
}

data "aws_caller_identity" "current" {}

check "workload_account" {
  assert {
    condition     = data.aws_caller_identity.current.account_id == var.workload_account_id
    error_message = "Refusing to manage resources in an unexpected AWS account."
  }
}

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
  source = "git::https://github.com/josephwegner/family-paas.git//terraform/modules/lambda-function?ref=main"
  for_each = {
    "example" = { s3_key = "${var.app_name}/${var.environment}/example.zip" }
  }

  function_name   = each.key
  app_name        = var.app_name
  environment     = var.environment
  lambda_role_arn = aws_iam_role.lambda_role.arn
  s3_bucket       = local.lambda_bucket
  s3_key          = each.value.s3_key
}

## Authentication is intentionally not scaffolded. Cross-account Cognito
## integration requires a separately approved platform design.

## Uncomment to give this app a dedicated on-demand table (PITR and deletion
## protection are enabled by default; add global_secondary_indexes only when
## a real query pattern needs one):
# module "table" {
#   source      = "git::https://github.com/josephwegner/family-paas.git//terraform/modules/dynamodb-table?ref=main"
#   table_name  = "${var.app_name}-data-${var.environment}"
#   environment = var.environment
#   hash_key    = "pk"
#   range_key   = "sk"
#   attributes = [
#     { name = "pk", type = "S" },
#     { name = "sk", type = "S" },
#   ]
# }

## Uncomment alongside module "table" above to scope the Lambda role to only
## that table (replaces the need for a broader inline policy):
# resource "aws_iam_role_policy" "lambda_table_access" {
#   name = "${var.app_name}-table-access-${var.environment}"
#   role = aws_iam_role.lambda_role.id
#
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [{
#       Effect = "Allow"
#       Action = [
#         "dynamodb:GetItem",
#         "dynamodb:PutItem",
#         "dynamodb:UpdateItem",
#         "dynamodb:DeleteItem",
#         "dynamodb:Query",
#         "dynamodb:BatchGetItem",
#         "dynamodb:BatchWriteItem",
#         "dynamodb:ConditionCheckItem",
#         "dynamodb:TransactGetItems",
#         "dynamodb:TransactWriteItems",
#       ]
#       Resource = [
#         module.table.table_arn,
#         "${module.table.table_arn}/index/*",
#       ]
#     }]
#   })
# }

module "api" {
  source      = "git::https://github.com/josephwegner/family-paas.git//terraform/modules/api-gateway?ref=main"
  app_name    = var.app_name
  environment = var.environment

  ## Restrict to explicit origins once this app has known dev/prod origins
  ## (defaults to "*" for apps without authenticated routes):
  # cors_allowed_origins = var.allowed_origins

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
  domain_name          = var.domain_name
  enable_custom_domain = var.enable_custom_domain
}
