output "cloudfront_domain" {
  description = "CloudFront distribution domain name"
  value       = aws_cloudfront_distribution.frontend.domain_name
}

output "cloudfront_distribution_id" {
  description = "CloudFront distribution ID"
  value       = aws_cloudfront_distribution.frontend.id
}

output "s3_bucket_name" {
  description = "S3 bucket name for frontend assets"
  value       = aws_s3_bucket.frontend.id
}

output "cloudfront_url" {
  description = "Full CloudFront URL"
  value       = "https://${aws_cloudfront_distribution.frontend.domain_name}"
}

output "custom_domain_validation_records" {
  description = "CNAME records to create manually at the external DNS provider before enabling the custom domain."
  value = var.domain_name == "" ? [] : [
    for option in aws_acm_certificate.frontend[0].domain_validation_options : {
      name  = option.resource_record_name
      type  = option.resource_record_type
      value = option.resource_record_value
    }
  ]
}

output "custom_domain_cname_target" {
  description = "External DNS CNAME target for the configured application hostname."
  value       = var.domain_name == "" ? null : aws_cloudfront_distribution.frontend.domain_name
}
