## ADDED Requirements

### Requirement: Linked-account cost attribution
The organization owner SHALL be able to attribute consolidated AWS cost and usage to each tenant's workload account.

#### Scenario: Multiple tenants incur charges
- **WHEN** two workload accounts incur AWS charges during a billing period
- **THEN** the management account's billing data identifies the charges by linked account

### Requirement: Organization-wide budget
The management account SHALL define one configurable monthly organization-wide cost budget with notifications for actual and forecast cost thresholds.

#### Scenario: Forecast threshold is crossed
- **WHEN** AWS forecasts organization spending above the configured forecast threshold
- **THEN** AWS Budgets sends a notification to the configured owner channel

#### Scenario: Actual threshold is crossed
- **WHEN** actual organization spending exceeds a configured actual threshold
- **THEN** AWS Budgets sends a notification to the configured owner channel

### Requirement: Budget is monitoring rather than enforcement
Family-PaaS documentation SHALL identify budget data and notifications as delayed monitoring and SHALL NOT represent the organization budget as a hard spending cap.

#### Scenario: Operator configures the budget
- **WHEN** the operator follows the organization budget documentation
- **THEN** the operator is warned that costs can continue to accrue before and after notification

### Requirement: Organization billing remains private
Normal tenant deployment roles SHALL NOT grant access to organization-wide billing or another tenant's cost details.

#### Scenario: Tenant requests organization billing data
- **WHEN** a tenant uses normal deployment credentials to request consolidated billing data
- **THEN** AWS denies the request
