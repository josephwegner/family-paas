resource "aws_cognito_user_pool_client" "this" {
  name         = coalesce(var.client_name, "${var.app_name}-${var.environment}")
  user_pool_id = var.user_pool_id

  generate_secret = false

  explicit_auth_flows = coalesce(var.explicit_auth_flows, [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
  ])

  # Cognito treats an omitted or empty write-attribute collection as its
  # permissive default. variables.tf rejects an explicitly empty collection.
  write_attributes = var.write_attributes

  supported_identity_providers = ["COGNITO"]

  prevent_user_existence_errors = "ENABLED"
  enable_token_revocation       = true

  access_token_validity  = var.access_token_validity_hours
  id_token_validity      = var.id_token_validity_hours
  refresh_token_validity = var.refresh_token_validity_days

  token_validity_units {
    access_token  = "hours"
    id_token      = "hours"
    refresh_token = "days"
  }
}
