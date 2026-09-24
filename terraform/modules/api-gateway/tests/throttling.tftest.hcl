mock_provider "aws" {}

variables {
  app_name    = "test-app"
  environment = "test"
  routes = [{
    route_key     = "GET /example"
    function_arn  = "arn:aws:lambda:us-east-1:111122223333:function:test:live"
    function_name = "arn:aws:lambda:us-east-1:111122223333:function:test:live"
  }]
}

run "default_throttling" {
  command = plan

  assert {
    condition     = aws_apigatewayv2_stage.default.default_route_settings[0].throttling_rate_limit == 10000
    error_message = "The default throttling rate limit must remain 10000 requests per second."
  }

  assert {
    condition     = aws_apigatewayv2_stage.default.default_route_settings[0].throttling_burst_limit == 5000
    error_message = "The default throttling burst limit must remain 5000 requests."
  }
}

run "custom_throttling" {
  command = plan

  variables {
    throttling_rate_limit  = 2
    throttling_burst_limit = 5
  }

  assert {
    condition     = aws_apigatewayv2_stage.default.default_route_settings[0].throttling_rate_limit == 2
    error_message = "The stage must use the configured throttling rate limit."
  }

  assert {
    condition     = aws_apigatewayv2_stage.default.default_route_settings[0].throttling_burst_limit == 5
    error_message = "The stage must use the configured throttling burst limit."
  }
}
