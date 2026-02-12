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
  }))
}
