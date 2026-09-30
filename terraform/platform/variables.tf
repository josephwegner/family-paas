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
  description = "Non-secret registry of person-workload or shared-services accounts and trusted state principals."
  type = map(object({
    workload_account_id    = string
    workload_principal_arn = string
  }))

  validation {
    condition = alltrue([
      for tenant in values(var.tenants) :
      can(regex("^arn:aws:iam::${tenant.workload_account_id}:role/.+$", tenant.workload_principal_arn))
    ])
    error_message = "Each workload_principal_arn must be an IAM role in its declared workload_account_id."
  }
}
