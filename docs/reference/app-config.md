# Application configuration

`app.config.json` is non-secret application configuration consumed by the
deploy CLI.

```json
{
  "name": "my-app",
  "tenantId": "tenant-a",
  "workloadAccountId": "111122223333",
  "environment": "prod",
  "region": "us-east-1",
  "terraform": {
    "stateBucket": "platform-terraform-state-444455556666",
    "stateRegion": "us-east-1",
    "statePrefix": "tenants/tenant-a/apps",
    "stateRoleArn": "arn:aws:iam::444455556666:role/platform-tenant-a-state"
  },
  "lambdas": ["example"],
  "frontend": {
    "buildCommand": "npm run build:frontend",
    "distDir": "dist"
  }
}
```

| Field | Source | Meaning |
|---|---|---|
| `name` | App owner | Stable lowercase application name |
| `tenantId` | Platform operator | Tenant registry key |
| `workloadAccountId` | Platform operator | Account where app resources are created |
| `environment` | App owner | Environment suffix such as `dev` or `prod` |
| `region` | App owner | Workload region |
| `terraform.stateBucket` | Platform operator | Central state bucket |
| `terraform.stateRegion` | Platform operator | State bucket region |
| `terraform.statePrefix` | Platform operator | Must start with `tenants/<tenantId>/` |
| `terraform.stateRoleArn` | Platform operator | Tenant-scoped state role |
| `lambdas` | App owner | Lambda directories beneath `lambdas/` |
| `frontend` | App owner | Frontend build command and output directory |

These values are safe to commit. Secrets belong in a secret manager or ignored
local inputs, never in `app.config.json`.

The CLI calls STS and refuses to build, initialize Terraform, upload, or update
resources when the active account differs from `workloadAccountId`.
