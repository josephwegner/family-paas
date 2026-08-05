output "api_endpoint" {
  description = "API Gateway endpoint URL"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

output "api_id" {
  description = "API Gateway ID"
  value       = aws_apigatewayv2_api.this.id
}

output "execution_arn" {
  description = "Execution ARN of the API Gateway"
  value       = aws_apigatewayv2_api.this.execution_arn
}

output "jwt_authorizer_id" {
  description = "ID of the JWT authorizer (null if auth was not configured)"
  value       = var.auth != null ? aws_apigatewayv2_authorizer.jwt[0].id : null
}

output "access_log_group_name" {
  description = "CloudWatch log group name for API access logs (null if disabled)"
  value       = var.enable_access_logging ? aws_cloudwatch_log_group.access_logs[0].name : null
}
