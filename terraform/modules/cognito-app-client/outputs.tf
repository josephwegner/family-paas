output "client_id" {
  description = "Cognito User Pool Client ID"
  value       = aws_cognito_user_pool_client.this.id
}

output "session_config" {
  description = "Non-secret session/token configuration for frontend session handling"
  value = {
    access_token_validity_hours = var.access_token_validity_hours
    id_token_validity_hours     = var.id_token_validity_hours
    refresh_token_validity_days = var.refresh_token_validity_days
    token_revocation_enabled    = aws_cognito_user_pool_client.this.enable_token_revocation
  }
}
