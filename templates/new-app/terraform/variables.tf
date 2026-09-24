variable "app_name" {
  description = "Application name"
  type        = string
  default     = "APP_NAME"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "region" {
  description = "Workload deployment region"
  type        = string
  default     = "us-east-1"
}

variable "workload_account_id" {
  description = "Expected tenant workload account ID"
  type        = string
}

variable "domain_name" {
  description = "Platform-operator-approved application hostname; empty disables custom DNS"
  type        = string
  default     = ""
}

variable "enable_custom_domain" {
  description = "Enable after ACM is issued and before creating the external application CNAME"
  type        = bool
  default     = false
}

variable "allowed_origins" {
  description = "Explicit browser origins (local dev + production) allowed to call this app's API. Only used if you wire cors_allowed_origins into module \"api\"."
  type        = list(string)
  default     = []
}

variable "throttling_rate_limit" {
  description = "Steady-state requests per second for the API's $default stage"
  type        = number
  default     = 10000
}

variable "throttling_burst_limit" {
  description = "Burst request limit for the API's $default stage"
  type        = number
  default     = 5000
}
