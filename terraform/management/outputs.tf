output "organization_id" {
  value = aws_organizations_organization.family.id
}

output "member_account_ids" {
  value = { for key, account in aws_organizations_account.member : key => account.id }
}

output "member_account_access_roles" {
  value = {
    for key, account in aws_organizations_account.member :
    key => "arn:aws:iam::${account.id}:role/${var.member_accounts[key].role_name}"
  }
}
