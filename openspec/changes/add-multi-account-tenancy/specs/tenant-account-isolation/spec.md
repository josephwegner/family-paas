## ADDED Requirements

### Requirement: One workload account per tenant
The platform SHALL map each tenant identifier to exactly one AWS workload account, and all application compute, storage, logs, data, CloudFront distributions, certificates, and deployment artifacts for that tenant SHALL be created in that account.

#### Scenario: Two tenants deploy applications
- **WHEN** two tenants deploy applications through Family-PaaS
- **THEN** each tenant's application resources are created only in the AWS account mapped to that tenant

### Requirement: Short-lived tenant access
The platform SHALL provide human tenant access through MFA-backed, short-lived AWS sessions and SHALL NOT require long-lived IAM user access keys.

#### Scenario: Tenant begins local deployment
- **WHEN** a tenant authenticates for a local Terraform or application deployment
- **THEN** the tenant receives a time-limited role session for only the tenant's workload account

### Requirement: Cross-tenant AWS access is absent
A tenant's supported identity and deployment roles SHALL NOT grant access to the Organizations management account, platform account resources except explicit tenant state and DNS operations, or another tenant's workload account.

#### Scenario: Tenant attempts to enumerate another account
- **WHEN** a tenant uses the credentials issued for the tenant's normal deployment workflow to call a resource-listing API in another workload account
- **THEN** AWS denies the request

### Requirement: Deployment account validation
Family-PaaS tooling SHALL verify the active STS account against the application's configured workload account before performing any mutating deployment operation and SHALL fail closed on mismatch.

#### Scenario: Wrong account is active
- **WHEN** a tenant starts Terraform initialization or an application deployment with credentials for an account other than the configured workload account
- **THEN** the command exits before uploading artifacts, changing infrastructure, or synchronizing frontend files

#### Scenario: Correct account is active
- **WHEN** the active STS account matches the application's configured workload account
- **THEN** tooling uses that validated account for workload-local resource naming and proceeds

### Requirement: Shared application data is not implicitly available
Tenant applications SHALL NOT receive access to the platform shared-media bucket or shared application DynamoDB table by default.

#### Scenario: Tenant application needs private storage
- **WHEN** an application provisions media or application data without a separately approved platform integration
- **THEN** the storage resource and its access policy are created in the tenant workload account
