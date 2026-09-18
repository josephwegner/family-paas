## ADDED Requirements

### Requirement: Central tenant-prefixed state
The platform SHALL store application Terraform state in a versioned, encrypted, non-public S3 bucket in the platform account under a distinct `tenants/<tenant>/` prefix.

#### Scenario: Tenant initializes an application
- **WHEN** a tenant initializes Terraform for one of the tenant's applications
- **THEN** Terraform selects a backend key beneath that tenant's state prefix and enables state locking

### Requirement: Tenant state least privilege
Each tenant SHALL assume a distinct platform state role that permits required state object and lock operations only within that tenant's prefix and does not permit reading, writing, deleting, or enumerating another tenant's state or shared platform state.

#### Scenario: Tenant reads own state
- **WHEN** a tenant's Terraform backend reads a state object beneath the assigned prefix
- **THEN** the platform state role permits the operation

#### Scenario: Tenant reads another prefix
- **WHEN** the same role requests a state object beneath another tenant's prefix or the shared platform prefix
- **THEN** AWS denies the operation

#### Scenario: Tenant lists the state bucket
- **WHEN** the tenant attempts an unconstrained listing of the central state bucket
- **THEN** AWS denies the operation or returns only keys beneath the assigned tenant prefix

### Requirement: Independent local Terraform workflow
Family-PaaS SHALL allow a tenant to run `terraform init`, `plan`, and `apply` locally without a platform deployment service or routine action by the platform owner.

#### Scenario: Tenant performs routine infrastructure change
- **WHEN** the tenant has a valid workload session and runs the documented initialization and Terraform commands
- **THEN** the backend uses the tenant state role while the AWS provider changes resources in the tenant workload account

### Requirement: Shared state is not a configuration interface
Application Terraform SHALL NOT read the platform's complete Terraform state through a `terraform_remote_state` data source.

#### Scenario: Application requires platform configuration
- **WHEN** application Terraform needs a non-sensitive platform value
- **THEN** the value is supplied through tenant configuration or a narrowly scoped platform interface without granting access to shared state

### Requirement: Backend configuration contains no durable secret
Generated backend configuration SHALL contain only resource identifiers and role settings and SHALL NOT contain long-lived AWS credentials.

#### Scenario: Generated initialization files are inspected
- **WHEN** a tenant or repository scanner inspects generated Terraform backend configuration
- **THEN** no access key, secret access key, session token, password, or private key is present
