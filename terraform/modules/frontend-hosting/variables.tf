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

variable "enable_custom_domain" {
  description = "Enable the CloudFront alias only after external DNS validation makes the workload ACM certificate ISSUED."
  type        = bool
  default     = false

  validation {
    condition     = !var.enable_custom_domain || var.domain_name != ""
    error_message = "domain_name is required when enable_custom_domain is true."
  }
}
