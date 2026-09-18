# Create and deploy a first app

Complete [workload onboarding](../operations/workload-onboarding.md) first.
The examples below use placeholders; replace every value supplied by the
platform operator.

## Scaffold the app

From a Family-PaaS checkout:

```bash
./scripts/create-app.sh my-app ../my-app
cd ../my-app
git init
npm install
```

The scaffolder excludes Terraform caches, state, plans, dependencies, and build
output. The generated repository includes its own `.gitignore`.

## Configure the tenant

Replace the placeholders in `app.config.json`. See
[the configuration reference](../reference/app-config.md) for every field.

Set the required Terraform input in an ignored file:

```hcl
# terraform/terraform.tfvars
workload_account_id = "<WORKLOAD_ACCOUNT_ID>"
```

Do not configure a custom domain for the first deployment.

## Seed the first Lambda artifact

Terraform creates a Lambda from an S3 object, so the initial ZIP must be
uploaded before the first infrastructure apply:

```bash
aws sso login --profile <TENANT_PROFILE>
AWS_PROFILE=<TENANT_PROFILE> npm run deploy:seed
```

`deploy:seed` validates the active account, builds each configured Lambda, and
uploads its ZIP. It does not attempt to update Lambda functions that do not yet
exist.

## Create the infrastructure

```bash
AWS_PROFILE=<TENANT_PROFILE> npm run terraform:init
AWS_PROFILE=<TENANT_PROFILE> terraform -chdir=terraform plan -out=first-app.tfplan
AWS_PROFILE=<TENANT_PROFILE> terraform -chdir=terraform apply first-app.tfplan
rm terraform/first-app.tfplan
```

Review the plan before applying. It should contain only workload-local app
resources and no organization, billing, platform-state, or DNS resources.

Do not pass variables again when applying a saved plan. A saved plan already
contains the variable values used to create it.

## Publish the frontend

The template includes a minimal static page. Replace it with a real frontend
when needed, then run:

```bash
AWS_PROFILE=<TENANT_PROFILE> npm run deploy:frontend
```

Test the API independently:

```bash
API_URL=$(AWS_PROFILE=<TENANT_PROFILE> terraform -chdir=terraform output -raw api_gateway_url)
curl "$API_URL/api/example"
```

The default CloudFront hostname is available from:

```bash
AWS_PROFILE=<TENANT_PROFILE> terraform -chdir=terraform output -raw cloudfront_url
```

Custom domains are optional. Follow
[DNS and certificates](../architecture/dns-and-certificates.md) only after the
default endpoint works.
