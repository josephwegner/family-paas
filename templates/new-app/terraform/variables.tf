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

variable "allowed_origins" {
  description = "Explicit browser origins (local dev + production) allowed to call this app's API. Only used if you wire cors_allowed_origins into module \"api\"."
  type        = list(string)
  default     = []
}
