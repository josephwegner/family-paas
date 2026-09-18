# Application deployment

Log in before each work session:

```bash
aws sso login --profile <TENANT_PROFILE>
```

## First deployment

Follow [Create and deploy a first app](../getting-started/first-app.md). The
initial order is important: seed Lambda ZIPs, apply Terraform, then publish the
frontend.

## Routine Lambda deployment

```bash
AWS_PROFILE=<TENANT_PROFILE> npm run deploy:lambdas
```

The command validates the account, builds and uploads each ZIP, publishes a new
Lambda version, and advances its `live` alias. API Gateway targets that alias.

## Routine frontend deployment

```bash
AWS_PROFILE=<TENANT_PROFILE> npm run deploy:frontend
```

## Infrastructure changes

```bash
AWS_PROFILE=<TENANT_PROFILE> npm run terraform:init
AWS_PROFILE=<TENANT_PROFILE> terraform -chdir=terraform plan
AWS_PROFILE=<TENANT_PROFILE> terraform -chdir=terraform apply
```

Use a saved plan for reviewed production changes. Never commit plans, state,
`.terraform/`, `.env`, or `*.tfvars` files.

## Rollback

For Lambda code, point the `live` alias at a previously published version and
then reconcile Terraform or redeploy the intended release. For infrastructure,
use a reviewed Terraform plan and resource-specific data recovery procedure;
do not restore state alone when underlying data has changed.
