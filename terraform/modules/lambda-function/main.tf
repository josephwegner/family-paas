resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${var.app_name}-${var.function_name}-${var.environment}"
  retention_in_days = var.log_retention_days

  tags = {
    Name        = "${var.app_name}-${var.function_name}-logs"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_lambda_function" "this" {
  function_name = "${var.app_name}-${var.function_name}-${var.environment}"
  role          = var.lambda_role_arn
  handler       = "index.handler"
  runtime       = "nodejs20.x"
  timeout       = var.timeout
  memory_size   = var.memory_size
  publish       = true

  s3_bucket = var.s3_bucket
  s3_key    = var.s3_key

  # Supplying this hash makes a new ZIP at an unchanged S3 key visible to
  # Terraform. With publish = true, Lambda then creates a new numbered version.
  source_code_hash = var.source_code_hash

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

  depends_on = [aws_cloudwatch_log_group.this]
}

# Stable alias apps/CI reference; repointing it to a prior aws_lambda_function.this.version
# is the rollback mechanism (each apply publishes a new immutable numbered version).
resource "aws_lambda_alias" "live" {
  name             = "live"
  function_name    = aws_lambda_function.this.function_name
  function_version = aws_lambda_function.this.version
}
