## Context

Family-PaaS currently assumes that shared infrastructure and every application live in AWS account `743837809639`. Application Terraform reads the complete shared state, the backend is hard-coded to the same state bucket, and the deploy CLI derives resource names from whichever account happens to be active. This works for one operator but cannot prevent another operator from enumerating account-wide resources.

The new operators are trusted family members who should independently run Terraform and application deployments from their own machines. Joe will own the AWS Organization and consolidated bill, but application names, infrastructure, data, logs, state, and usage details must remain private between tenants. Cost prevention is not a security objective; clear linked-account attribution and one organization-wide alert are sufficient.

## Goals / Non-Goals

**Goals:**

- Use one AWS workload account per person as the application isolation and cost-attribution boundary.
- Let each tenant initialize Terraform, plan, apply, and deploy without Joe participating in routine deployments.
- Keep organization administration separate from shared platform infrastructure.
- Keep central state private while retaining owner control of DNS at the existing external provider.
- Keep all application resources, including deployment artifacts and TLS certificates, in the tenant workload account.
- Detect accidental deployment with credentials for the wrong AWS account before changing resources.
- Provide a migration path for existing applications that avoids accidental destruction.

**Non-Goals:**

- Preventing tenant usage from contributing to the consolidated AWS bill.
- Per-account budgets, automatic spending shutdown, or cost recovery.
- Service control policies in the initial implementation. AWS Organizations and SCPs have no separate charge, but account separation supplies the required privacy boundary and the family accepts operational cost risk.
- Cross-account Cognito app clients or a final multi-tenant identity architecture.
- Hiding public DNS names or public applications from internet discovery.
- A hosted deployment service, CI/CD control plane, or approval step for tenant deployments.
- One AWS account per application.

## Decisions

### Separate management, platform, and workload accounts

The AWS Organizations management account SHALL contain organization and billing administration only. A platform member account SHALL own central Terraform state. Each person SHALL receive one workload member account containing all of that person's applications. DNS remains at the existing external provider and is not an AWS platform resource.

This follows the AWS account security boundary and keeps platform resources out of the management account, where SCPs would not apply. Combining management and platform accounts would reduce account count but would place operational resources in the organization's most privileged account.

### Use IAM Identity Center sessions for human access

Each brother SHALL authenticate with MFA-backed IAM Identity Center and receive a short-lived role only in his workload account. The role MAY have broad application-development permissions in that account, but it SHALL NOT grant organization, platform, or other workload-account access. Long-lived IAM access keys are not part of the supported workflow.

The exact permission set should cover the services Family-PaaS provisions rather than use unrestricted `AdministratorAccess`. This is not intended to control spending; it reduces accidental account-administration and cross-account changes.

### Run Terraform locally with separate backend and workload credentials

Tenant Terraform runs locally. The normal AWS session targets the tenant workload account and is used by the AWS provider. The S3 backend separately assumes a tenant-specific state role in the platform account.

The state role SHALL allow object and lock operations only under `tenants/<tenant>/` and SHALL either omit bucket listing or constrain listing to that prefix. State objects use S3 encryption, versioning, public-access blocking, and native S3 lockfiles. Shared state SHALL not be exposed through `terraform_remote_state`; required non-sensitive platform settings are supplied through generated backend/provider configuration.

Because Terraform backend blocks cannot use input variables, Family-PaaS SHALL provide an initialization command that reads tenant configuration, verifies the caller account, and invokes `terraform init` with generated backend arguments. Generated backend configuration SHALL not contain long-lived credentials and SHALL not be committed.

Alternatives considered were tenant-local state buckets and a central deployment service. Tenant-local state is simpler but gives Joe less central backup and recovery control. A deployment service provides stronger mediation but conflicts with independent local operation and adds unnecessary platform complexity.

### Use a tenant registry and fail closed on account mismatch

A platform-maintained, non-secret tenant registry SHALL map a stable tenant ID to workload account ID, state prefix, and state role ARN. Application configuration SHALL select a tenant by ID and record the expected workload account ID. Custom domain names remain application configuration reviewed by the platform owner before external DNS records are created.

Before upload, Lambda update, frontend synchronization, Terraform initialization, or other mutating deployment work, tooling SHALL call STS and fail if the active account differs from the configured workload account. Resource names and deployment bucket names SHALL use the configured workload account after validation rather than treating the caller account as tenant selection.

### Keep deployment artifacts in each workload account

Every workload account SHALL have its own versioned, encrypted Lambda deployment bucket. Application Lambda functions SHALL read packages from that account-local bucket. Empty S3 buckets have no meaningful fixed resource charge, and this avoids cross-account S3 policies and source-code disclosure.

The shared media bucket and `shared-app-data` table remain platform-owned but SHALL NOT be available to tenant applications as part of this change. Tenant-private media and data belong in workload-local buckets and tables.

### Keep DNS external and certificates workload-local

`joewegner.com` remains authoritative at its existing external DNS provider. Family-PaaS SHALL NOT create a Route 53 hosted zone, DNS role, or cross-account DNS permissions. The platform owner coordinates names and manually creates DNS records, preventing overlap outside Terraform.

Each workload account requests non-exportable ACM certificates in `us-east-1`. Terraform outputs ACM's validation CNAME without waiting for DNS. The platform owner creates that CNAME at the external provider and waits for ACM to report `ISSUED`; a later apply enables the CloudFront alias with the workload-owned certificate. Terraform then outputs the CloudFront domain for the platform owner to use as the application's external CNAME target. Standard non-exportable ACM public certificates used by integrated AWS services have no direct certificate charge.

This is not self-service custom DNS: tenants can deploy immediately at the default CloudFront hostname, but custom names require platform-owner participation. Route 53 and delegated zones were rejected because the existing provider already owns the domain and manual record volume is expected to remain low.

### Attribute cost by linked account and add one organization budget

AWS consolidated billing already groups cost and usage by linked account. The management account SHALL define one organization-wide monthly cost budget with actual and forecast notifications to Joe. Tenant users SHALL not receive access to organization-wide billing data.

AWS Budgets are delayed monitoring, not a spending cap. Per-account budgets and budget actions can be added later without changing tenant isolation.

### Defer Cognito integration

The new-app template SHALL not imply that a workload-account provider can create a client in the platform Cognito pool. Existing unauthenticated applications can migrate. An app that needs authentication requires a separate decision about shared identity, app membership, and who manages platform-account Cognito resources.

## Risks / Trade-offs

- [Broad permissions within a workload account can create unexpected cost] -> Rely on linked-account attribution and the organization budget for the accepted initial risk; keep SCPs and per-account budgets as later additive controls.
- [AWS Budgets can alert after cost has already accrued] -> Document that the budget is monitoring only and retain payer access for incident response.
- [Manual DNS creates an owner bottleneck or naming collision] -> Keep custom domains optional, review names before creating records, and use the default CloudFront hostname until records are ready.
- [Public applications remain externally discoverable] -> Document that account privacy protects AWS enumeration, not public DNS, Certificate Transparency, crawling, or passive DNS discovery.
- [Central state access can leak another tenant's infrastructure] -> Use distinct roles and prefixes, deny unconstrained listing, test cross-prefix reads/writes, and never expose shared state through remote-state data sources.
- [Identity Center role ARNs can change if assignments are deleted and recreated] -> Isolate trusted principal configuration in account bootstrap outputs and update platform role trust as part of identity assignment changes.
- [Moving existing Terraform-managed resources across accounts can recreate stateful resources] -> Inventory each app, establish Joe's workload account first, and use explicit import/state migration with reviewed plans and backups.
- [An organization or platform account bootstrap failure can lock out operators] -> Apply account creation, Identity Center assignments, and state roles in separate reviewed stages while retaining root break-glass access with MFA.

## Migration Plan

1. Use existing account `743837809639` as the Organizations management account, enable all organization features, and create `joe-platform`, `joe-workload`, and `scott` member accounts without moving application resources.
2. Configure root contacts, root MFA, IAM Identity Center, Joe's administrative assignments, and break-glass recovery for every account.
3. Create the platform state bucket, tenant state roles, and organization-wide budget.
4. Bootstrap Joe's workload-local deployment bucket and validate state isolation with harmless fixtures.
5. Add tenant-aware configuration and CLI account validation while retaining the current applications in place.
6. Back up current state and data. Migrate the `weather-app` development environment to Joe's workload account as the stateless canary, importing or recreating resources deliberately and switching DNS only after validation.
7. Migrate stateful applications one at a time with application-specific data transfer and rollback plans. Keep old resources until the new deployment is verified.
8. Create each brother's workload account and Identity Center assignment, then run an acceptance test proving local Terraform works while Joe/platform/other-tenant resources cannot be listed or read.
9. Remove obsolete single-account shared-state references and permissions after all existing applications are migrated.

Rollback before an application DNS cutover consists of discarding the new workload resources and restoring the backed-up state. After cutover, route DNS back to the old distribution and restore the old state as the source of truth; stateful data changes require an application-specific reverse synchronization plan.

## Open Questions

- Can the current resources in management account `743837809639` be migrated safely after member account creation?
- Which initial names beneath `joewegner.com` should be assigned to Joe and Scott without overlap?
- What exact service permissions do the initial workload permission sets need based on the first brother-hosted application?
