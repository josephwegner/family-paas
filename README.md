# family-paas

Shared platform for family web apps. Provides Terraform modules, npm packages, and deploy tooling so each app stays in its own repo but shares a common infrastructure pattern.

## What's in this repo

```
terraform/
  modules/          Reusable Terraform modules (Lambda, API Gateway, CloudFront, DynamoDB)
  shared/           Shared infrastructure (Lambda deployment bucket, shared DynamoDB, shared media bucket)
packages/
  lambda-response/  @family-paas/lambda-response - Lambda response helpers
  lambda-simulator/ @family-paas/lambda-simulator - Express-based Lambda simulator for local dev
  deploy/           @family-paas/deploy - CLI deploy tool that reads app.config.json
templates/
  new-app/          Starter template for scaffolding a new app
scripts/
  create-app.sh     Scaffold a new app repo from the template
```

## Shared resources

These live in `terraform/shared/` and are referenced by apps via `terraform_remote_state`:

| Resource | Name | Purpose |
|----------|------|---------|
| S3 bucket | `lambda-deployments-{account_id}` | Stores Lambda deployment zips for all apps |
| S3 bucket | `shared-media-{account_id}` | Shared media/asset storage |
| DynamoDB table | `shared-app-data` | Shared key-value store (pk/sk schema) |

Apps access them in their `terraform/main.tf`:
```hcl
data "terraform_remote_state" "shared" {
  backend = "s3"
  config = {
    bucket = "terraform-state-743837809639"
    key    = "shared/terraform.tfstate"
    region = "us-east-1"
  }
}

locals {
  lambda_bucket = data.terraform_remote_state.shared.outputs.lambda_deployments_bucket
}
```

## Terraform modules

### lambda-function
Creates a Lambda function with standard tags and NODE_ENV=production.

```hcl
module "lambdas" {
  source   = "git::https://github.com/josephwegner/family-paas.git//terraform/modules/lambda-function?ref=main"
  for_each = { "my-func" = { s3_key = "my-app/prod/my-func.zip" } }

  function_name   = each.key
  app_name        = "my-app"
  environment     = "prod"
  lambda_role_arn = aws_iam_role.lambda_role.arn
  s3_bucket       = local.lambda_bucket
  s3_key          = each.value.s3_key
}
```

### api-gateway
Creates an HTTP API v2 with routes, integrations, and Lambda permissions.

```hcl
module "api" {
  source      = "git::https://github.com/josephwegner/family-paas.git//terraform/modules/api-gateway?ref=main"
  app_name    = "my-app"
  environment = "prod"
  routes = [
    { route_key = "GET /api/hello", function_arn = module.lambdas["my-func"].invoke_arn, function_name = module.lambdas["my-func"].function_name },
  ]
}
```

### frontend-hosting
Creates S3 + CloudFront with OAC, API origin, and SPA fallback.

```hcl
module "frontend" {
  source               = "git::https://github.com/josephwegner/family-paas.git//terraform/modules/frontend-hosting?ref=main"
  app_name             = "my-app"
  environment          = "prod"
  api_gateway_endpoint = module.api.api_endpoint
  domain_name          = "my-app.example.com"    # optional
  acm_certificate_arn  = "arn:aws:acm:..."       # optional
}
```

### dynamodb-table
Creates a DynamoDB table with optional GSIs.

```hcl
module "my_table" {
  source     = "git::https://github.com/josephwegner/family-paas.git//terraform/modules/dynamodb-table?ref=main"
  table_name = "my-app-data-prod"
  environment = "prod"
  hash_key   = "id"
  attributes = [{ name = "id", type = "S" }]
}
```

## npm packages

Install from git (no registry needed):

```json
{
  "@family-paas/lambda-response": "github:josephwegner/family-paas#main",
  "@family-paas/lambda-simulator": "github:josephwegner/family-paas#main",
  "@family-paas/deploy": "github:josephwegner/family-paas#main"
}
```

### @family-paas/lambda-response

```ts
import { createSuccessResponse, createErrorResponse } from '@family-paas/lambda-response';

return createSuccessResponse({ data: 'hello' });       // 200
return createSuccessResponse({ data: 'created' }, 201); // custom status
return createErrorResponse(404, 'Not found');
```

### @family-paas/lambda-simulator

Used in `local-dev/server.ts` to simulate Lambda + API Gateway locally:

```ts
import { simulateLambda } from '@family-paas/lambda-simulator';
app.get('/api/hello', (req, res) => simulateLambda(handler, req, res));
```

### @family-paas/deploy

CLI tool that reads `app.config.json` and handles the full deploy pipeline:

```bash
npm run deploy              # lambdas + frontend
npm run deploy:lambdas      # lambdas only
npm run deploy:frontend     # frontend only
```

## Creating a new app

```bash
./scripts/create-app.sh my-cool-app ~/Code/my-cool-app
cd ~/Code/my-cool-app
git init
npm install
```

## Deploy workflow

**Routine code changes:** `npm run deploy` from within the app repo.

**Infrastructure changes** (adding lambdas, changing routes, etc.): `cd terraform && terraform plan && terraform apply` within the app repo.

## Current apps

| App | Repo | Domain |
|-----|------|--------|
| Weather | josephwegner/weather | weather.joewegner.com |
| Truth or Dare | josephwegner/truthordare | (CloudFront default) |
