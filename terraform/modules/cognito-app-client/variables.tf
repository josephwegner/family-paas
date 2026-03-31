variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. prod)"
  type        = string
}

variable "user_pool_id" {
  description = "Cognito User Pool ID from shared infrastructure"
  type        = string
}
