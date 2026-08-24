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

variable "client_name" {
  description = "Optional stable app-client name override. Defaults to <app_name>-<environment>."
  type        = string
  default     = null

  validation {
    condition     = var.client_name == null ? true : trimspace(var.client_name) != ""
    error_message = "client_name must be null or a non-empty string."
  }
}

variable "explicit_auth_flows" {
  description = "Optional non-empty set of Cognito explicit auth flows. Defaults to SRP and refresh-token authentication when omitted."
  type        = set(string)
  default     = null

  validation {
    condition     = var.explicit_auth_flows == null ? true : length(var.explicit_auth_flows) > 0
    error_message = "explicit_auth_flows must be null or contain at least one flow; Cognito applies defaults to an empty collection."
  }
}

variable "write_attributes" {
  description = "Optional non-empty set of user-pool attributes this client may write. Omission preserves Cognito's default permissions; an empty set is rejected because Cognito treats it as omitted."
  type        = set(string)
  default     = null

  validation {
    condition     = var.write_attributes == null ? true : length(var.write_attributes) > 0
    error_message = "write_attributes must be null or contain at least one attribute; Cognito treats an empty collection as its permissive default."
  }
}

variable "access_token_validity_hours" {
  description = "Access token validity in hours"
  type        = number
  default     = 1
}

variable "id_token_validity_hours" {
  description = "ID token validity in hours"
  type        = number
  default     = 1
}

variable "refresh_token_validity_days" {
  description = "Refresh token validity in days"
  type        = number
  default     = 30
}
