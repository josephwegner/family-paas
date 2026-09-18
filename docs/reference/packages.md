# npm packages and deploy CLI

Pin the Git dependency to a release tag or commit SHA:

```json
{
  "dependencies": {
    "family-paas": "github:OWNER/family-paas#<TAG_OR_SHA>"
  }
}
```

## Deploy CLI

| Command | Purpose |
|---|---|
| `npm run terraform:init` | Validate account and initialize tenant state |
| `npm run deploy:seed` | Build and upload ZIPs before the first Terraform apply |
| `npm run deploy:lambdas` | Build, upload, publish, and advance Lambda `live` aliases |
| `npm run deploy:frontend` | Build and synchronize frontend files |
| `npm run deploy` | Deploy existing Lambdas and frontend |

All commands require an active named AWS profile, for example:

```bash
AWS_PROFILE=<TENANT_PROFILE> npm run deploy:lambdas
```

## `family-paas/lambda-response`

Provides API Gateway success and error response helpers.

## `family-paas/lambda-simulator`

Adapts Express requests into API Gateway events for local Lambda development.
Simulated JWT claims are development fixtures, not a substitute for production
authentication or authorization tests.

## `family-paas/auth`

Provides framework-neutral Cognito client helpers. Behavior such as
email-as-username, automatic verification, and password policy depends on the
configured user pool. API Gateway JWT validation removes the need to validate
token signatures in handlers, but handlers must still authorize each action and
resource.
