## 1. Resolve Deployment Inputs

- [x] 1.1 Record management account `743837809639`, the platform and workload account names/emails, externally hosted root domain, $500 monthly budget with 80% actual and 100% forecast thresholds, and `joe@joewegner.com` notification recipient in environment-specific configuration excluded from source control where appropriate.
- [x] 1.2 Inventory current shared and application resources, Terraform state addresses, DNS records, stateful data, and account ownership; select a stateless migration canary and document resource-specific migration/rollback commands.
- [x] 1.3 Add automated policy fixtures that define allowed and denied state-prefix, cross-account, and billing-access scenarios before provisioning live access.

## 2. Organization And Identity Foundation

- [x] 2.1 Add a management-account Terraform root that creates or adopts the AWS Organization and creates the platform and tenant workload member accounts without placing application resources in the management account.
- [x] 2.2 Add configurable organization-wide AWS Budget resources with actual and forecast notifications, and document linked-account cost attribution and notification delay.
- [x] 2.3 Configure and document IAM Identity Center assignments with MFA-backed short-lived sessions so each tenant receives access only to the mapped workload account and normal roles do not expose organization billing.
- [x] 2.4 Add workload permission sets/policies for the Family-PaaS service set, excluding Organizations, account administration, billing, platform resources, and cross-account role assumption except tenant-specific platform roles.
- [x] 2.5 Document root contact, root MFA, break-glass recovery, account onboarding, and account suspension procedures.

## 3. Platform State Isolation

- [x] 3.1 Add a platform-account Terraform root for a versioned, encrypted, public-blocked central state bucket using native S3 state lockfiles.
- [x] 3.2 Define the tenant registry schema and configuration mapping tenant IDs to workload accounts, state prefixes, and state role ARNs.
- [x] 3.3 Create one state access role and policy per tenant with object and lock access limited to `tenants/<tenant>/` and bucket listing absent or prefix-constrained.
- [x] 3.4 Add policy tests proving own-prefix state operations succeed while shared-state, other-prefix, unconstrained-list, and other-account operations fail.

## 4. External DNS And Certificates

- [x] 4.1 Remove Route 53 hosted zones, tenant DNS roles, DNS registry allocations, and cross-account DNS providers from the platform and application Terraform.
- [x] 4.2 Add workload Terraform that requests a non-exportable ACM certificate in `us-east-1` and outputs manual validation CNAME records without blocking the first apply.
- [x] 4.3 Gate the CloudFront custom alias on explicit enablement after ACM issuance and output the external DNS CNAME target.
- [x] 4.4 Document the owner-mediated validation and application CNAME workflow, naming-conflict review, and default CloudFront fallback.

## 5. Workload Bootstrap

- [x] 5.1 Add workload-account bootstrap Terraform for a versioned, encrypted, non-public Lambda deployment bucket in each tenant account.
- [x] 5.2 Remove application access to the platform shared-media bucket and `shared-app-data` table from the tenant onboarding path, and document workload-local storage as the default.
- [x] 5.3 Remove or disable the new-app Cognito client example that cannot be managed from a workload account, and document authentication as a separate architecture decision.

## 6. Tenant-Aware Local Tooling

- [x] 6.1 Keep `app.config.json` and deploy validation limited to tenant ID, expected workload account ID, and state role/configuration; custom DNS is a Terraform and owner-mediated concern.
- [x] 6.2 Add a tested Terraform initialization command that validates STS identity and supplies tenant-prefixed S3 backend and role-assumption arguments without writing durable credentials.
- [x] 6.3 Update the deploy CLI to validate the configured account before builds with mutating follow-up, uploads, Lambda updates, and frontend synchronization, and add wrong-account fail-closed tests.
- [x] 6.4 Update deployment bucket and frontend resource resolution to use the validated configured workload account rather than implicit caller-account tenant selection.
- [x] 6.5 Replace application `terraform_remote_state` access and hard-coded backend/account values in the new-app template with generated tenant configuration and the initialization command.

## 7. Migration And Acceptance

- [ ] 7.1 Back up the existing state and stateful data, create Joe's workload and platform foundations, and verify break-glass access before moving an application.
- [ ] 7.2 Migrate the selected stateless application into Joe's workload account, review for unintended replacement, validate the new endpoint, cut over DNS, and exercise rollback.
- [x] 7.3 Produce per-application migration runbooks for remaining stateful applications, including data copy, import/state operations, DNS cutover, and reverse synchronization where required.
- [ ] 7.4 Onboard a test brother tenant and complete an end-to-end local `init`, `plan`, `apply`, Lambda deployment, and frontend deployment; separately verify the owner-mediated custom-domain workflow if a custom name is requested.
- [ ] 7.5 Run negative acceptance tests proving the tenant cannot enumerate or modify Joe's resources, platform/shared state, consolidated billing, or another workload account, and has no AWS DNS permissions.
- [x] 7.6 Update the README with account architecture, login and local deployment workflows, certificate cost behavior, budget limitations, cost attribution, public-discovery limitations, and optional future SCP/per-account-budget guidance.

## 8. Verification And Cleanup

- [x] 8.1 Run Terraform formatting and validation for every new or modified root, module, template, example, and policy fixture.
- [x] 8.2 Run deploy package type checks and automated tests, including configuration validation and wrong-account cases.
- [ ] 8.3 Remove obsolete single-account state references and permissions only after all consumers have migrated, then confirm existing application deployments still succeed.
- [ ] 8.4 Review final plans in each account and verify that no tenant role grants wildcard cross-account assumption, shared state visibility, Route 53 access, or organization billing access.
