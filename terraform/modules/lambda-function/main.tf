resource "aws_lambda_function" "this" {
  function_name = "${var.app_name}-${var.function_name}-${var.environment}"
  role          = var.lambda_role_arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = var.timeout
  memory_size   = var.memory_size

  s3_bucket = var.s3_bucket
  s3_key    = var.s3_key

  environment {
    variables = merge(
      { NODE_ENV = "production" },
      var.environment_variables
    )
  }

  tags = {
    Name        = "${var.app_name}-${var.function_name}"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
