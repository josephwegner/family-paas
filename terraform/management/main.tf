data "aws_caller_identity" "current" {}

check "management_account" {
  assert {
    condition     = data.aws_caller_identity.current.account_id == var.management_account_id
    error_message = "Refusing to manage the organization from an unexpected AWS account."
  }
}

resource "aws_organizations_organization" "family" {
  feature_set                   = "ALL"
  aws_service_access_principals = ["sso.amazonaws.com"]
}

resource "aws_organizations_account" "member" {
  for_each = var.member_accounts

  depends_on = [aws_organizations_organization.family]

  name      = each.value.name
  email     = each.value.email
  role_name = each.value.role_name

  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_budgets_budget" "organization_monthly" {
  name         = "family-paas-organization-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  dynamic "notification" {
    for_each = var.budget_notification_emails
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = var.budget_actual_threshold
      threshold_type             = "PERCENTAGE"
      notification_type          = "ACTUAL"
      subscriber_email_addresses = [notification.value]
    }
  }

  dynamic "notification" {
    for_each = var.budget_notification_emails
    content {
      comparison_operator        = "GREATER_THAN"
      threshold                  = var.budget_forecast_threshold
      threshold_type             = "PERCENTAGE"
      notification_type          = "FORECASTED"
      subscriber_email_addresses = [notification.value]
    }
  }
}

locals {
  identity_center_enabled = var.identity_center_instance_arn != null
  tenant_account_keys = {
    joe   = "joe_workload"
    scott = "scott"
  }
  assignments = local.identity_center_enabled ? {
    for tenant_id, principal_id in var.tenant_principal_ids : tenant_id => {
      principal_id = principal_id
      account_key  = local.tenant_account_keys[tenant_id]
    }
  } : {}
}

resource "aws_ssoadmin_permission_set" "workload_developer" {
  for_each = local.assignments
  provider = aws.identity_center

  name             = "FamilyPaas-${title(each.key)}-Developer"
  description      = "Family-PaaS ${each.key} workload deployment without organization, billing, or account administration access"
  instance_arn     = var.identity_center_instance_arn
  session_duration = "PT4H"
}

resource "aws_ssoadmin_permission_set_inline_policy" "workload_developer" {
  for_each = local.assignments
  provider = aws.identity_center

  instance_arn       = var.identity_center_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.workload_developer[each.key].arn
  inline_policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat([
      {
        Sid    = "WorkloadServices"
        Effect = "Allow"
        Action = [
          "acm:*", "apigateway:*", "cloudfront:*", "cloudwatch:*",
          "dynamodb:*", "ec2:Describe*", "iam:Get*", "iam:List*",
          "iam:PassRole", "iam:CreateRole", "iam:DeleteRole",
          "iam:TagRole", "iam:UntagRole",
          "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:PutRolePolicy",
          "iam:DeleteRolePolicy", "lambda:*", "logs:*", "s3:*",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
      ], length(lookup(var.platform_role_arns, each.key, [])) > 0 ? [
      {
        Sid      = "TenantPlatformRoles"
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = var.platform_role_arns[each.key]
      }
    ] : [])
  })
}

resource "aws_ssoadmin_account_assignment" "tenant" {
  for_each = local.assignments
  provider = aws.identity_center

  instance_arn       = var.identity_center_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.workload_developer[each.key].arn
  principal_id       = each.value.principal_id
  principal_type     = "USER"
  target_id          = aws_organizations_account.member[each.value.account_key].id
  target_type        = "AWS_ACCOUNT"
}
