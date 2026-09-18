# Workload onboarding

## Platform-operator steps

1. Create or register the workload account in the management root.
2. Create the tenant's IAM Identity Center user and MFA policy.
3. Assign a tenant-specific permission set to only that workload account.
4. Add the workload principal to the platform tenant registry.
5. Apply the platform root to create the tenant state role.
6. Add that exact state role ARN to the tenant's permission set.
7. Give the tenant the portal URL, region, account ID, tenant ID, state bucket,
   and state role ARN.

## Tenant steps

Configure a named profile:

```bash
aws configure sso
aws sso login --profile <TENANT_PROFILE>
aws sts get-caller-identity --profile <TENANT_PROFILE>
```

Confirm the returned account matches the workload account supplied by the
operator. Then clone Family-PaaS and run:

```bash
npm run bootstrap:workload -- \
  <TENANT_ID> \
  <WORKLOAD_ACCOUNT_ID> \
  <TENANT_PROFILE> \
  <STATE_BUCKET> \
  <STATE_ROLE_ARN>
```

The command verifies account identity, initializes tenant-scoped remote state,
shows a saved plan, requires typing `yes`, applies the workload deployment
bucket, and removes the temporary plan.

Do not create IAM users or long-lived access keys.
