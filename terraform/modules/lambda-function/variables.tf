variable "function_name" {
  description = "Short name for the Lambda function (e.g. 'current', 'get-dares')"
  type        = string
}

variable "app_name" {
  description = "Application name"
  type        = string
}

variable "environment" {
  description = "Environment name (e.g. prod)"
  type        = string
}

variable "lambda_role_arn" {
  description = "IAM role ARN for the Lambda function"
  type        = string
}

variable "s3_bucket" {
  description = "S3 bucket containing the deployment package"
  type        = string
}

variable "s3_key" {
  description = "S3 key for the deployment package zip"
  type        = string
}

variable "source_code_hash" {
  description = "Base64-encoded SHA-256 hash of the Lambda deployment ZIP. When supplied, Terraform detects artifact-content changes at a stable S3 key."
  type        = string
  default     = null
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 10
}

variable "memory_size" {
  description = "Lambda function memory in MB"
  type        = number
  default     = 512
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention for this function's log group"
  type        = number
  default     = 30
}
