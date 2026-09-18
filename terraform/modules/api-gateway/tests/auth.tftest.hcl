mock_provider "aws" {}

variables {
  app_name    = "test-app"
  environment = "test"
  routes = [{
    route_key     = "GET /private"
    function_arn  = "arn:aws:lambda:us-east-1:111122223333:function:test:live"
    function_name = "arn:aws:lambda:us-east-1:111122223333:function:test:live"
    auth_required = true
  }]
}

run "protected_route_requires_auth" {
  command = plan

  expect_failures = [aws_apigatewayv2_api.this]
}

run "protected_route_with_auth" {
  command = plan

  variables {
    auth = {
      issuer   = "https://example.invalid"
      audience = ["test-client"]
    }
  }

  assert {
    condition     = aws_apigatewayv2_route.this["GET /private"].authorization_type == "JWT"
    error_message = "Protected routes must use JWT authorization."
  }
}
