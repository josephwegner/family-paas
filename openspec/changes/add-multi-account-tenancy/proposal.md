## Why

Family members need to deploy and manage their own Family-PaaS applications without being able to enumerate, inspect, or modify another person's applications. AWS accounts provide the appropriate workload, access, and cost-attribution boundary while allowing the family to retain shared platform conventions and consolidated billing.

## What Changes

- Introduce a Family-PaaS tenant model that maps each person to one AWS workload account.
- Add organization and account bootstrap infrastructure for a dedicated management account, a platform account, and tenant workload accounts.
- Give each tenant short-lived access to run Terraform and application deployments locally only in their own workload account.
- Store Terraform state centrally while restricting each tenant to their own state prefix and preventing access to shared or other-tenant state.
- Keep application compute, storage, logs, data, deployment artifacts, CloudFront distributions, and ACM certificates in the tenant workload account.
- Keep DNS at the existing external provider. The platform owner manually creates ACM validation and application records, while workload Terraform outputs the required CNAME names and targets.
- Add organization-wide cost attribution and budget alerts while leaving per-account budgets and service control policies optional and out of scope.
- Defer cross-account Cognito support; authenticated applications require a separate design decision before onboarding.
- **BREAKING**: Replace hard-coded account IDs, state locations, and caller-account-derived deployment assumptions with tenant-aware configuration.

## Capabilities

### New Capabilities
- `tenant-account-isolation`: Maps each tenant to a workload account and limits tenant credentials and deployments to that account.
- `tenant-terraform-state`: Allows local Terraform workflows with centrally stored, tenant-isolated state.
- `external-dns-publication`: Supports workload-local certificates and CloudFront custom domains through owner-mediated records at the existing external DNS provider.
- `organization-cost-visibility`: Provides organization-wide budget alerts and clear cost attribution by AWS account.

### Modified Capabilities

None.

## Impact

- Adds Terraform roots/modules for AWS Organizations, account bootstrap, identity access, central state policy, and budget monitoring.
- Changes the new-app Terraform template, backend initialization, provider configuration, and `app.config.json` tenant/account settings.
- Changes the deploy CLI so it validates the selected account and uses workload-local deployment buckets instead of implicit caller-account behavior.
- Requires migration of existing application resources and state into Joe's workload account; resource migration must be planned to avoid unintended replacement.
- Requires one ACM public certificate per workload account for custom CloudFront domains. Non-exportable ACM certificates have no direct certificate charge, though normal CloudFront and DNS usage remains billable.
- Does not grant brothers access to the Organizations management account, platform resources, Joe's workload account, other tenants' state, or other tenants' cost details.
