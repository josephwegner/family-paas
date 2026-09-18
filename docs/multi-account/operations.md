# Account and identity operations

## Root and break-glass controls

Before provisioning member accounts:

1. Enable hardware or passkey MFA on every root user.
2. Store root credentials and recovery information in the family password vault.
3. Verify alternate security, operations, and billing contacts for each account.
4. Do not create root access keys. Root is break-glass only.
5. Test `OrganizationAccountAccessRole` from the management account before
   removing any bootstrap access path.

## IAM Identity Center

Enable IAM Identity Center in the management account after organization
creation. Create Joe and Scott users, require MFA, record their principal IDs,
and apply the management root again with `identity_center_instance_arn` and
`tenant_principal_ids`. The workload permission set uses four-hour sessions and
does not grant Organizations, account, billing, or Cost Explorer APIs.

Use `aws configure sso` on each operator machine. Long-lived IAM access keys
and repository secrets are not part of the supported deployment workflow.

## Onboarding

1. Create or register the workload account in the management root.
2. Assign exactly one tenant principal to that account.
3. Add a tenant registry entry with the workload principal, then apply the
   platform root.
4. Add the generated platform state role ARN to the workload permission set.
5. Apply workload bootstrap from the tenant workload session.
6. Run positive and negative acceptance checks before sharing access.

## Suspension

Remove the IAM Identity Center account assignment first. Preserve state and
data, rotate any application secrets, invalidate active sessions if needed, and
only then suspend or close the member account. AWS account closure is not a
Terraform destroy operation.
