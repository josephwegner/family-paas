variable "region" {
  description = "AWS region used for global-service API calls."
  type        = string
  default     = "us-east-1"
}

variable "management_account_id" {
  description = "Existing standalone account that will become the Organizations management account."
  type        = string
  default     = "743837809639"

  validation {
    condition     = can(regex("^[0-9]{12}$", var.management_account_id))
    error_message = "management_account_id must be a 12-digit AWS account ID."
  }
}

variable "member_accounts" {
  description = "Member accounts to create. Account emails must be globally unique in AWS."
  type = map(object({
    name      = string
    email     = string
    role_name = optional(string, "OrganizationAccountAccessRole")
  }))
}

variable "monthly_budget_usd" {
  description = "Organization-wide monthly budget amount in USD."
  type        = number
  default     = 500
}

variable "budget_actual_threshold" {
  description = "Percentage of the monthly budget that triggers the actual-cost alert."
  type        = number
  default     = 80
}

variable "budget_forecast_threshold" {
  description = "Percentage of the monthly budget that triggers the forecast-cost alert."
  type        = number
  default     = 100
}

variable "budget_notification_emails" {
  description = "Email recipients for actual and forecast budget alerts."
  type        = set(string)
  default     = ["joe@joewegner.com"]
}

variable "identity_center_instance_arn" {
  description = "IAM Identity Center instance ARN. Leave null until Identity Center is enabled."
  type        = string
  default     = null
  nullable    = true
}

variable "identity_center_region" {
  description = "Region containing the IAM Identity Center organization instance."
  type        = string
  default     = "us-east-2"
}

variable "tenant_principal_ids" {
  description = "Tenant ID to IAM Identity Center USER or GROUP principal ID."
  type        = map(string)
  default     = {}
}

variable "platform_role_arns" {
  description = "Tenant ID to platform state role ARNs that the workload permission set may assume."
  type        = map(set(string))
  default     = {}
}
