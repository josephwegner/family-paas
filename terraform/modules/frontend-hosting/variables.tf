variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. prod)"
  type        = string
}

variable "api_gateway_endpoint" {
  description = "API Gateway endpoint URL (e.g. https://abc123.execute-api.us-east-1.amazonaws.com)"
  type        = string
}

variable "domain_name" {
  description = "Custom domain name (leave empty for CloudFront default domain)"
  type        = string
  default     = ""
}

variable "acm_certificate_arn" {
  description = "ARN of the ACM certificate for custom domain (must be in us-east-1)"
  type        = string
  default     = ""
}
