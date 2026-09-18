# Costs and budgets

AWS Organizations uses consolidated billing. The payer can attribute usage by
linked workload account without giving tenants access to organization-wide
billing data.

The management Terraform root creates one configurable monthly budget with
actual-cost and forecast-cost notifications. An actual threshold reports spend
already recorded; a forecast threshold reports AWS's estimate for the month.
Both can be delayed and neither is a hard spending cap.

Choose amounts, percentages, and recipients for the deployment rather than
copying values from historical records. Per-account budgets or budget actions
can be added when stronger cost controls are needed.

AWS Organizations and service control policies have no separate service fee.
Service control policies can add preventive guardrails, but they do not replace
workload-account isolation and can create operational lockout risk if deployed
without testing.
