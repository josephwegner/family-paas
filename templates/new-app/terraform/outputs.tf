output "api_gateway_url" {
  description = "API Gateway endpoint URL"
  value       = module.api.api_endpoint
}

output "cloudfront_url" {
  description = "CloudFront distribution URL"
  value       = module.frontend.cloudfront_url
}

output "s3_bucket" {
  description = "S3 bucket name for frontend"
  value       = module.frontend.s3_bucket_name
}

output "custom_domain_validation_records" {
  description = "CNAME records the platform owner must create at the external DNS provider"
  value       = module.frontend.custom_domain_validation_records
}

output "custom_domain_cname_target" {
  description = "CNAME target for the application hostname after the certificate is issued"
  value       = module.frontend.custom_domain_cname_target
}
