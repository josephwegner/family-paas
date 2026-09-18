# Multi-account deployment record

> **Historical deployment-specific record**
>
> Captured: 2026-09-18. These identifiers describe one installation. They are
> not example values and must not be copied into another deployment.

## Confirmed values

| Setting | Value |
|---|---|
| Existing management account | `743837809639` |
| Current bootstrap identity | `arn:aws:iam::743837809639:user/josephwegner` |
| Organization status before migration | Standalone account; superseded by organization creation |
| Platform account | `joe-platform` / `family-paas-platform@joewegner.com` |
| Joe workload account | `joe-workload` / `family-paas-workload@joewegner.com` |
| Scott workload account | `scott` / `swegner2@gmail.com` |
| Root domain | `joewegner.com` |
| Monthly organization budget | $500 USD |
| Actual-cost alert | 80% ($400) |
| Forecast-cost alert | 100% ($500) |
| Budget recipient | `joe@joewegner.com` |
| Migration canary | `weather-app` production environment |

The actual alert provides warning before the full budget is consumed. The
forecast alert fires when AWS predicts that the month will reach the budget.
AWS Budgets is delayed monitoring, not a hard cap; costs can continue to accrue.

## Bootstrap results

The staged Terraform roots produced member-account IDs, IAM Identity Center
assignments, tenant state roles, and the central state bucket. Operational
values remain in ignored local Terraform variable files.

`joewegner.com` remains at its existing external DNS provider. Custom names are
reviewed for conflicts and created manually by the platform owner.
