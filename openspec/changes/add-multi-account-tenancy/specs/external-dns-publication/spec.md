## ADDED Requirements

### Requirement: DNS remains external
The platform SHALL leave `joewegner.com` at its existing external DNS provider and SHALL NOT create Route 53 hosted zones or grant tenant DNS permissions.

#### Scenario: Tenant deploys without a custom domain
- **WHEN** a tenant deploys an application without platform-owner DNS action
- **THEN** the application remains available through its default CloudFront hostname

### Requirement: Workload-local certificate
Each custom-domain application SHALL use a non-exportable ACM public certificate in `us-east-1` owned by the same workload account as its CloudFront distribution.

#### Scenario: Tenant requests a custom domain
- **WHEN** workload Terraform requests a certificate for the configured hostname
- **THEN** Terraform outputs the DNS validation CNAME without requiring Route 53 access or waiting indefinitely for manual DNS

### Requirement: Owner-mediated certificate validation
The platform owner SHALL create ACM validation records at the external DNS provider and SHALL enable the CloudFront custom alias only after ACM reports the workload certificate as `ISSUED`.

#### Scenario: Certificate is pending validation
- **WHEN** the validation CNAME has not been created or propagated
- **THEN** CloudFront continues using its default certificate and hostname

#### Scenario: Certificate is issued
- **WHEN** ACM reports the workload certificate as `ISSUED` and custom-domain enablement is configured
- **THEN** CloudFront uses that certificate for the configured hostname

### Requirement: Owner-mediated application record
Terraform SHALL output the CloudFront distribution hostname, and the platform owner SHALL create the external DNS CNAME or provider-supported alias after verifying that the requested name does not conflict with an existing record.

#### Scenario: Custom hostname is published
- **WHEN** the certificate is issued and CloudFront accepts the alias
- **THEN** the platform owner points the approved external DNS name to the Terraform output

### Requirement: Public discovery limitation is documented
Family-PaaS documentation SHALL state that AWS account isolation does not conceal public hostnames or applications from Certificate Transparency, DNS queries, passive DNS, crawlers, or users who know the URL.

#### Scenario: Operator reviews privacy guarantees
- **WHEN** an operator reads the multi-account privacy documentation
- **THEN** the documentation distinguishes private AWS resource enumeration from public internet discoverability
