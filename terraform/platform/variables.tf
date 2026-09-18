variable "region" {
  description = "Platform resource region."
  type        = string
  default     = "us-east-1"
}

variable "platform_account_id" {
  description = "Expected platform AWS account ID."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.platform_account_id))
    error_message = "platform_account_id must be a 12-digit AWS account ID."
  }
}

variable "state_bucket_name" {
  description = "Globally unique central Terraform state bucket name."
  type        = string
}

variable "tenants" {
  description = "Non-secret registry of workload accounts and trusted state principals."
  type = map(object({
    workload_account_id    = string
    workload_principal_arn = string
  }))
}
