# Accounts and Terraform state

Family-PaaS uses three account roles:

- **Management account:** AWS Organizations, consolidated billing, budgets,
  and IAM Identity Center governance. It should not host application workloads.
- **Platform account:** central Terraform state and one state role per tenant.
- **Workload account:** all applications owned by one tenant.

Each tenant role can access only keys beneath `tenants/<tenant>/`. Bootstrap
state uses `tenants/<tenant>/bootstrap/terraform.tfstate`; application state
uses `tenants/<tenant>/apps/<app>/<environment>/terraform.tfstate`.

State uses S3 encryption, versioning, public-access blocking, and native S3
lockfiles. Apps receive non-secret platform values through configuration and do
not read the platform's full state with `terraform_remote_state`.

AWS account isolation prevents tenants from enumerating another tenant's
private resources. It does not hide public hostnames, certificates, or internet
applications.
