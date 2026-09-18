# Family-PaaS

Family-PaaS is a small, self-hosted application platform for trusted groups.
It provides reusable Terraform modules, TypeScript helpers, an application
template, and local deployment commands for AWS.

Each tenant uses a separate AWS workload account. A management account owns
organization, billing, and identity governance; a platform account owns
tenant-isolated Terraform state. Application infrastructure, data, logs,
deployment artifacts, CloudFront distributions, and ACM certificates remain in
the tenant's workload account.

## Repository layout

```text
terraform/
  management/          Organization, accounts, budget, and Identity Center
  platform/            Central state bucket and tenant-scoped state roles
  workload-bootstrap/  Workload-local deployment bucket
  modules/             Reusable application infrastructure modules
  shared/              Legacy single-account resources
packages/
  deploy/              Account-aware build and deployment CLI
  lambda-response/     API Gateway response helpers
  lambda-simulator/    Local Lambda/API Gateway simulator
  auth/                Cognito client helpers
templates/new-app/     New application template
scripts/               Scaffolding and workload bootstrap commands
```

## Start here

1. Install the [prerequisites](docs/getting-started/prerequisites.md).
2. Read the [account and state architecture](docs/architecture/accounts-and-state.md).
3. Ask a platform operator to create your workload account, Identity Center
   assignment, and tenant state role.
4. Follow [workload onboarding](docs/operations/workload-onboarding.md).
5. Follow the [first application guide](docs/getting-started/first-app.md).

Routine application deployment and infrastructure changes are covered in the
[deployment guide](docs/operations/app-deployment.md).

## Core safety properties

- Commands validate the active AWS account before changing resources.
- Tenant state roles can access only `tenants/<tenant>/` in the platform state
  bucket.
- Applications do not read platform state through `terraform_remote_state`.
- New applications use workload-local storage and deployment buckets.
- Authentication is optional, but a route marked `auth_required` cannot be
  deployed without a JWT authorizer configuration.
- Custom DNS stays with an external provider and requires platform-operator
  coordination.
- Durable IAM access keys are not part of the supported workflow.

## Documentation

- [Prerequisites](docs/getting-started/prerequisites.md)
- [Create and deploy a first app](docs/getting-started/first-app.md)
- [Application configuration](docs/reference/app-config.md)
- [Terraform modules](docs/reference/terraform-modules.md)
- [npm packages and deploy CLI](docs/reference/packages.md)
- [Accounts and state](docs/architecture/accounts-and-state.md)
- [Identity and authorization](docs/architecture/identity-and-authorization.md)
- [DNS and certificates](docs/architecture/dns-and-certificates.md)
- [Costs and budgets](docs/architecture/costs-and-budgets.md)
- [Platform administration](docs/operations/platform-administration.md)
- [Workload onboarding](docs/operations/workload-onboarding.md)
- [Application deployment](docs/operations/app-deployment.md)
- [Deployment-specific migration records](docs/migrations/multi-account/README.md)

## Project status

The multi-account architecture is operational. The `terraform/shared` root and
the Cognito app-client module are retained for legacy applications and are not
part of new-tenant onboarding. Cross-account Cognito integration requires a
separate design.

Consumers should pin Terraform modules and the Git dependency to a release tag
or commit SHA. Tracking `main` is appropriate only when intentionally testing
the latest platform changes.
