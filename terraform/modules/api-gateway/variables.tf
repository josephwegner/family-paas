variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. prod)"
  type        = string
}

variable "routes" {
  description = "List of API routes with their Lambda function targets"
  type = list(object({
    route_key     = string
    function_arn  = string
    function_name = string
    auth_required = optional(bool, false)
  }))
}

variable "auth" {
  description = "Optional JWT auth configuration. When set, creates a JWT authorizer for routes with auth_required = true."
  type = object({
    issuer   = string
    audience = list(string)
  })
  default = null
}

variable "cors_allowed_origins" {
  description = "Explicit list of allowed CORS origins. Defaults to '*' for backward compatibility with apps that don't need scoping; apps with authenticated routes should pass explicit origins."
  type        = list(string)
  default     = ["*"]
}

variable "enable_access_logging" {
  description = "Enable privacy-safe structured access logging to CloudWatch (request id, route, status, latency only)"
  type        = bool
  default     = true
}

variable "access_log_retention_days" {
  description = "CloudWatch Logs retention for the access log group"
  type        = number
  default     = 30
}

variable "throttling_rate_limit" {
  description = "Steady-state requests per second for the $default stage"
  type        = number
  default     = 10000
}

variable "throttling_burst_limit" {
  description = "Burst request limit for the $default stage"
  type        = number
  default     = 5000
}
