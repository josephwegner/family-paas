# family-paas

Shared platform for family web apps. Provides Terraform modules, npm packages, and deploy tooling so each app stays in its own repo but shares a common infrastructure pattern.

## What's in this repo

```
terraform/
  modules/          Reusable Terraform modules (Lambda, API Gateway, CloudFront, DynamoDB, Cognito)
  shared/           Shared infrastructure (Lambda deployment bucket, shared DynamoDB, shared media bucket, Cognito user pool)
packages/
  lambda-response/  family-paas/lambda-response - Lambda response helpers
  lambda-simulator/ family-paas/lambda-simulator - Express-based Lambda simulator for local dev
  deploy/           family-paas/deploy - Deploy CLI that reads app.config.json
  auth/             family-paas/auth - Frontend auth helpers for Cognito
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
| Cognito User Pool | `family-paas-users` | Shared auth — one pool, separate app clients per app |

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
Creates a Lambda function with standard tags, NODE_ENV=production, a published
version for each code update, and a stable `live` alias.

```hcl
module "lambdas" {
  source   = "git::https://github.com/josephwegner/family-paas.git//terraform/modules/lambda-function?ref=main"
  for_each = {
    "my-func" = {
      s3_key          = "my-app/prod/my-func.zip"
      source_code_hash = var.my_func_source_code_hash
    }
  }

  function_name   = each.key
  app_name        = "my-app"
  environment     = "prod"
  lambda_role_arn = aws_iam_role.lambda_role.arn
  s3_bucket       = local.lambda_bucket
  s3_key          = each.value.s3_key
  source_code_hash = each.value.source_code_hash
}
```

#### Stable S3 keys and code updates

When an application replaces a ZIP at the same S3 key, pass its
base64-encoded **raw SHA-256** as `source_code_hash`. This makes the ZIP's
content part of the Terraform configuration: a changed hash updates the Lambda
code, `publish = true` creates a new immutable numbered version, and the
`live` alias advances to it. Omitting the optional value preserves the existing
behavior for consumers that do not need this detection.

For a ZIP at `dist/lambdas/session.zip`, generate the Terraform value with:

```bash
openssl dgst -sha256 -binary dist/lambdas/session.zip | base64
```

For example, a release-specific Terraform input can be supplied as
`session_lambda_source_code_hash` and wired into the module:

```hcl
variable "session_lambda_source_code_hash" {
  description = "Base64-encoded raw SHA-256 of dist/lambdas/session.zip"
  type        = string
}

module "lambdas" {
  # existing configuration
  source_code_hash = var.session_lambda_source_code_hash
}
```

See [`terraform/modules/lambda-function/examples/stable-s3-key`](terraform/modules/lambda-function/examples/stable-s3-key)
for an apply-level verification fixture.

### api-gateway
Creates an HTTP API v2 with routes, integrations, and Lambda permissions. Optionally adds a JWT authorizer for Cognito-based auth.

```hcl
module "api" {
  source      = "git::https://github.com/josephwegner/family-paas.git//terraform/modules/api-gateway?ref=main"
  app_name    = "my-app"
  environment = "prod"

  # Optional: enable JWT auth (requires cognito-app-client module)
  auth = {
    issuer   = data.terraform_remote_state.shared.outputs.cognito_user_pool_issuer
    audience = [module.auth.client_id]
  }

  routes = [
    { route_key = "GET /api/public", function_arn = module.lambdas["public"].invoke_arn, function_name = module.lambdas["public"].function_name },
    { route_key = "GET /api/private", function_arn = module.lambdas["private"].invoke_arn, function_name = module.lambdas["private"].function_name, auth_required = true },
  ]
}
```

When `auth` is set, routes with `auth_required = true` require a valid JWT in the `Authorization` header. Routes without `auth_required` (or with it set to `false`) remain public. If `auth` is omitted entirely, the module behaves exactly as before.

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

### cognito-app-client
Creates a Cognito app client in the shared user pool for a specific app.

```hcl
module "auth" {
  source       = "git::https://github.com/josephwegner/family-paas.git//terraform/modules/cognito-app-client?ref=main"
  app_name     = "my-app"
  environment  = "prod"
  user_pool_id = data.terraform_remote_state.shared.outputs.cognito_user_pool_id
}
```

Outputs `client_id` — pass this to the API Gateway `auth` config and your frontend auth setup.

Optional inputs support clients with narrower responsibilities:

- `client_name` overrides the derived `<app_name>-<environment>` name.
- `explicit_auth_flows` replaces the default SRP and refresh-token flows.
- `write_attributes` configures an explicit non-empty attribute allowlist.

Both collection overrides reject an empty set. Cognito treats an empty
`WriteAttributes` collection as omitted and restores its permissive default for
standard attributes; an empty collection is not a deny-all policy.

See [the Todone Cognito client handoff](docs/todone-cognito-client-handoff.md)
for the reviewed two-client pattern and its mandatory AWS acceptance checks.

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

One dependency, installed from git (no registry needed):

```json
{
  "family-paas": "github:josephwegner/family-paas#main"
}
```

Packages are exposed via subpath exports. Since apps use `esbuild` (for lambda bundling) and `tsx` (for local dev), the TypeScript source is consumed directly with no build step.

### family-paas/lambda-response

```ts
import { createSuccessResponse, createErrorResponse } from 'family-paas/lambda-response';

return createSuccessResponse({ data: 'hello' });       // 200
return createSuccessResponse({ data: 'created' }, 201); // custom status
return createErrorResponse(404, 'Not found');
```

### family-paas/lambda-simulator

Used in `local-dev/server.ts` to simulate Lambda + API Gateway locally:

```ts
import { simulateLambda } from 'family-paas/lambda-simulator';
app.get('/api/hello', (req, res) => simulateLambda(handler, req, res));
```

For authenticated routes, pass `{ simulateAuth: true }` to decode the JWT from the `Authorization` header and inject claims into `event.requestContext.authorizer.jwt`:

```ts
app.get('/api/private', (req, res) => simulateLambda(handler, req, res, { simulateAuth: true }));
```

### family-paas/auth

Frontend auth helpers wrapping AWS Cognito. Framework-agnostic — works with React, Vue, vanilla JS, etc. Apps need to install `amazon-cognito-identity-js` as a peer dependency.

```ts
import { createAuth } from 'family-paas/auth';

const auth = createAuth({
  userPoolId: 'us-east-1_XXXXX',  // from shared Terraform output
  clientId: 'abc123',              // from cognito-app-client module output
});

// Sign up
await auth.signUp('user@example.com', 'MyPassword123');
await auth.confirmSignUp('user@example.com', '123456'); // code from verification email

// Sign in
const session = await auth.signIn('user@example.com', 'MyPassword123');

// Make authenticated API calls
const token = await auth.getIdToken();
fetch('/api/private', {
  headers: { Authorization: `Bearer ${token}` },
});

// Sign out
auth.signOut();
```

Additional methods:

- `completeNewPassword(email, tempPassword, newPassword)` — for admin-created accounts that require a password change on first login
- `forgotPassword(email)` — sends a verification code to the user's email
- `confirmForgotPassword(email, code, newPassword)` — completes the password reset
- `getSession()` — returns the current session (auto-refreshes expired tokens), or `null` if not signed in
- `getCurrentUserEmail()` — returns the signed-in user's email, or `null`

When `signIn` encounters a new-password-required challenge, it rejects with a `NewPasswordRequiredError`. Catch this to show a new-password form, then call `completeNewPassword`.

#### Reading the authenticated user in Lambda handlers

For routes with `auth_required = true`, API Gateway validates the JWT and injects claims into the event. No auth logic needed in the handler:

```ts
export const handler = async (event: APIGatewayProxyEvent) => {
  const claims = (event.requestContext as any).authorizer?.jwt?.claims;
  const userId = claims?.sub;
  const email = claims?.email;
  // ...
};
```

### family-paas/deploy

Deploy CLI that reads `app.config.json`. Run via tsx in npm scripts:

```json
{
  "deploy": "tsx node_modules/family-paas/packages/deploy/src/index.ts",
  "deploy:lambdas": "tsx node_modules/family-paas/packages/deploy/src/index.ts --lambdas-only",
  "deploy:frontend": "tsx node_modules/family-paas/packages/deploy/src/index.ts --frontend-only"
}
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
