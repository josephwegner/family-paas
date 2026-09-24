# Terraform modules

Pin module sources to a release tag or commit SHA:

```hcl
source = "git::https://github.com/OWNER/family-paas.git//terraform/modules/lambda-function?ref=<TAG_OR_SHA>"
```

## `lambda-function`

Creates a Lambda function, CloudWatch log group, immutable published version,
and stable `live` alias. API Gateway integrations should use
`alias_invoke_arn`; Lambda permissions should use `qualified_arn`.

When Terraform owns artifact promotion, provide `source_code_hash` as the
base64-encoded raw SHA-256 of the ZIP:

```bash
openssl dgst -sha256 -binary dist/lambdas/example.zip | base64
```

The deploy CLI's routine Lambda path publishes a new version and advances the
same `live` alias.

## `api-gateway`

Creates an HTTP API, routes, Lambda integrations and permissions, optional JWT
authorizer, CORS configuration, and privacy-safe access logs.

Stage throttling can be configured with `throttling_rate_limit` (steady-state
requests per second) and `throttling_burst_limit`. They default to `10000` and
`5000`, respectively, for backward compatibility. These best-effort limits can
help control traffic and cost, but they are not authentication or hard spend
caps.

A route with `auth_required = true` requires the module-level `auth` object.
Terraform rejects the configuration instead of silently creating a public
route. JWT authentication validates the token; application handlers must still
enforce ownership, roles, scopes, and resource-level authorization.

## `frontend-hosting`

Creates a private versioned S3 bucket, CloudFront origin access control,
CloudFront distribution, API origin, and SPA fallback. With `domain_name` set,
it also requests a workload-owned ACM certificate in `us-east-1` and outputs
manual validation records. See [DNS and certificates](../architecture/dns-and-certificates.md).

## `dynamodb-table`

Creates a workload-local DynamoDB table with optional secondary indexes,
point-in-time recovery, and deletion protection defaults.

## `cognito-app-client`

Legacy module for creating a client when Terraform runs in the same account as
the user pool. It does not provide cross-account identity integration and is not
part of new-tenant onboarding.
