# Prerequisites

Family-PaaS supports macOS and Linux environments with a POSIX shell.

Install:

- Git
- Node.js 20 or newer and npm
- AWS CLI v2 with IAM Identity Center support
- Terraform 1.10 or newer
- `zip`
- `rsync`

Verify the tools before onboarding:

```bash
git --version
node --version
npm --version
aws --version
terraform version
zip --version
rsync --version
```

Terraform 1.10 or newer is required for native S3 state lockfiles. On macOS,
one installation option is:

```bash
brew install tenv
tenv tf install 1.10.5
tenv tf use 1.10.5
```

## AWS access

A platform operator must provide:

- An IAM Identity Center access-portal URL
- The Identity Center region
- A workload AWS account ID
- A tenant ID
- A tenant state bucket and state role ARN

Use short-lived Identity Center sessions. Do not create IAM users, IAM access
keys, or repository secrets for routine deployment.
