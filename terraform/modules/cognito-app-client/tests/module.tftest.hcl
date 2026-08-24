mock_provider "aws" {}

variables {
  app_name     = "example"
  environment  = "prod"
  user_pool_id = "us-east-1_EXAMPLE"
}

run "legacy_caller_keeps_existing_defaults" {
  command = plan

  assert {
    condition     = aws_cognito_user_pool_client.this.name == "example-prod"
    error_message = "Omitting client_name must preserve the existing derived name."
  }

  assert {
    condition = aws_cognito_user_pool_client.this.explicit_auth_flows == toset([
      "ALLOW_USER_SRP_AUTH",
      "ALLOW_REFRESH_TOKEN_AUTH",
    ])
    error_message = "Omitting explicit_auth_flows must preserve SRP and refresh-token authentication."
  }

  assert {
    condition     = var.write_attributes == null
    error_message = "Omitting write_attributes must remain valid for existing callers."
  }
}

run "authenticated_client_accepts_sentinel_allowlist" {
  command = plan

  variables {
    client_name      = "example-pwa-prod"
    write_attributes = ["custom:browser_write_guard"]
  }

  assert {
    condition     = aws_cognito_user_pool_client.this.name == "example-pwa-prod"
    error_message = "The client-name override must pass through unchanged."
  }

  assert {
    condition     = aws_cognito_user_pool_client.this.write_attributes == toset(["custom:browser_write_guard"])
    error_message = "The authenticated-client sentinel allowlist must pass through unchanged."
  }
}

run "registration_client_accepts_restricted_contract" {
  command = plan

  variables {
    client_name         = "example-registration-prod"
    explicit_auth_flows = ["ALLOW_CUSTOM_AUTH"]
    write_attributes    = ["email"]
  }

  assert {
    condition     = aws_cognito_user_pool_client.this.explicit_auth_flows == toset(["ALLOW_CUSTOM_AUTH"])
    error_message = "The registration-only auth-flow override must replace the module defaults."
  }

  assert {
    condition     = aws_cognito_user_pool_client.this.write_attributes == toset(["email"])
    error_message = "The registration-only email allowlist must pass through unchanged."
  }
}

run "empty_write_allowlist_is_rejected" {
  command = plan

  variables {
    write_attributes = []
  }

  expect_failures = [
    var.write_attributes,
  ]
}

run "empty_auth_flow_override_is_rejected" {
  command = plan

  variables {
    explicit_auth_flows = []
  }

  expect_failures = [
    var.explicit_auth_flows,
  ]
}
