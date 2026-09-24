resource "aws_apigatewayv2_api" "this" {
  name          = "${var.app_name}-api-${var.environment}"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = var.cors_allowed_origins
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["content-type", "x-amz-date", "authorization", "x-api-key", "x-amz-security-token"]
    max_age       = 300
  }

  tags = {
    Name        = "${var.app_name}-api"
    Environment = var.environment
    ManagedBy   = "terraform"
  }

  lifecycle {
    precondition {
      condition     = var.auth != null || !anytrue([for route in var.routes : route.auth_required])
      error_message = "Routes with auth_required = true require the module-level auth configuration."
    }
  }
}

resource "aws_cloudwatch_log_group" "access_logs" {
  count             = var.enable_access_logging ? 1 : 0
  name              = "/aws/apigateway/${var.app_name}-${var.environment}"
  retention_in_days = var.access_log_retention_days

  tags = {
    Name        = "${var.app_name}-api-access-logs"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_apigatewayv2_stage" "default" {
  api_id      = aws_apigatewayv2_api.this.id
  name        = "$default"
  auto_deploy = true

  default_route_settings {
    throttling_burst_limit = var.throttling_burst_limit
    throttling_rate_limit  = var.throttling_rate_limit
  }

  dynamic "access_log_settings" {
    for_each = var.enable_access_logging ? [1] : []
    content {
      destination_arn = aws_cloudwatch_log_group.access_logs[0].arn
      # Privacy-safe fields only: request id, route, method, status, latency, and
      # authorizer error (denial outcome). No headers, query strings, or bodies.
      format = jsonencode({
        requestId            = "$context.requestId"
        routeKey             = "$context.routeKey"
        httpMethod           = "$context.httpMethod"
        status               = "$context.status"
        responseLength       = "$context.responseLength"
        integrationLatencyMs = "$context.integrationLatency"
        latencyMs            = "$context.responseLatency"
        authorizerError      = "$context.authorizer.error"
        errorMessage         = "$context.error.message"
      })
    }
  }

  tags = {
    Name        = "${var.app_name}-api-stage"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

resource "aws_apigatewayv2_integration" "this" {
  for_each = { for r in var.routes : r.route_key => r }

  api_id                 = aws_apigatewayv2_api.this.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = each.value.function_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_authorizer" "jwt" {
  count = var.auth != null ? 1 : 0

  api_id           = aws_apigatewayv2_api.this.id
  authorizer_type  = "JWT"
  identity_sources = ["$request.header.Authorization"]
  name             = "${var.app_name}-jwt-auth"

  jwt_configuration {
    issuer   = var.auth.issuer
    audience = var.auth.audience
  }
}

resource "aws_apigatewayv2_route" "this" {
  for_each = { for r in var.routes : r.route_key => r }

  api_id    = aws_apigatewayv2_api.this.id
  route_key = each.value.route_key
  target    = "integrations/${aws_apigatewayv2_integration.this[each.key].id}"

  authorization_type = each.value.auth_required && var.auth != null ? "JWT" : "NONE"
  authorizer_id      = each.value.auth_required && var.auth != null ? aws_apigatewayv2_authorizer.jwt[0].id : null
}

resource "aws_lambda_permission" "this" {
  for_each = { for r in var.routes : r.route_key => r }

  statement_id  = "AllowAPIGatewayInvoke-${sha256(each.key)}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.this.execution_arn}/*/*"
}
