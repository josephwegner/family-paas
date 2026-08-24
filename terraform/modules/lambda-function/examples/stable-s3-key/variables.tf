variable "function_name" {
  description = "Short Lambda name"
  type        = string
  default     = "session"
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "lambda_role_arn" {
  description = "Lambda execution role ARN"
  type        = string
}

variable "s3_bucket" {
  description = "Bucket containing the deployment ZIP"
  type        = string
}

variable "s3_key" {
  description = "Stable key for the deployment ZIP"
  type        = string
  default     = "example/prod/session.zip"
}

variable "source_code_hash" {
  description = "Base64-encoded raw SHA-256 of the ZIP at s3_key"
  type        = string
}
