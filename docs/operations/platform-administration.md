# Platform administration

This runbook describes the reusable bootstrap order. Deployment-specific IDs,
emails, budgets, and profiles belong in ignored Terraform variable files.

## Management foundation

1. Secure the existing management-account root user with phishing-resistant
   MFA and tested recovery information. Do not create root access keys.
2. Populate `terraform/management` inputs with globally unique member-account
   emails, budget settings, and the expected management account ID.
3. Verify the active account with `aws sts get-caller-identity`.
4. Run `terraform init`, save a plan, and verify it contains only organization,
   member-account, budget, and intended identity-governance resources.
5. Apply the reviewed plan and verify the generated member-account access role
   before removing any bootstrap access path.

Account creation is consequential and AWS account closure is not an ordinary
Terraform destroy operation.

## IAM Identity Center

1. Enable the organization IAM Identity Center instance in the management
   account and record its region and ARN.
2. Create or connect human identities and require MFA.
3. Record principal IDs in ignored management-root inputs.
4. Apply permission sets and account assignments from the management account.
5. Verify each user sees only the intended workload account.

Identity Center is regional. Use an explicitly aliased Terraform provider when
its region differs from the general management provider region.

## Platform foundation

1. Assume the platform account's bootstrap role.
2. Populate `terraform/platform` with the platform account ID, globally unique
   state bucket, and tenant workload principals.
3. Save and review the plan. It should contain only the protected state bucket,
   tenant state roles, and prefix-scoped policies.
4. Apply and record the state bucket and role outputs.
5. Add each exact state role ARN to only the corresponding tenant permission
   set in the management root.

The platform root bootstraps its own state bucket, so its initial state is
local. Back it up securely. If moving that state into remote storage later,
use `terraform init -migrate-state`, preserve a pre-migration copy, and verify a
no-change plan before deleting the local copy.

## Root and recovery controls

- Keep root users as break-glass identities only.
- Verify root MFA and account contacts after each member account is created.
- Store recovery material in an organization-approved secrets vault.
- Test administrative role assumption periodically.
- Preserve versioned state and document restore procedures.

## Tenant suspension

Remove the Identity Center assignment first. Preserve state and data, rotate
application secrets, and invalidate sessions if necessary. Suspend or close an
AWS account only after retention and recovery requirements are satisfied.
