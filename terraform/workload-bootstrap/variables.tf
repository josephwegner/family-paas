variable "region" {
  type    = string
  default = "us-east-1"
}

variable "workload_account_id" {
  description = "Expected tenant workload account ID."
  type        = string

  validation {
    condition     = can(regex("^[0-9]{12}$", var.workload_account_id))
    error_message = "workload_account_id must be a 12-digit AWS account ID."
  }
}
