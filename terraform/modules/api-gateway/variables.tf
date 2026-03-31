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
