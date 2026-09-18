# Multi-account deployment inputs

## Confirmed values

| Setting | Value |
|---|---|
| Existing management account | `743837809639` |
| Current bootstrap identity | `arn:aws:iam::743837809639:user/josephwegner` |
| Organization status before migration | Standalone account; no organization |
| Platform account | `joe-platform` / `family-paas-platform@joewegner.com` |
| Joe workload account | `joe-workload` / `family-paas-workload@joewegner.com` |
| Scott workload account | `scott` / `swegner2@gmail.com` |
| Root domain | `joewegner.com` |
| Monthly organization budget | $500 USD |
| Actual-cost alert | 80% ($400) |
| Forecast-cost alert | 100% ($500) |
| Budget recipient | `joe@joewegner.com` |
| Migration canary | `weather-app` development environment |

The actual alert provides warning before the full budget is consumed. The
forecast alert fires when AWS predicts that the month will reach the budget.
AWS Budgets is delayed monitoring, not a hard cap; costs can continue to accrue.

## Values produced during bootstrap

Account IDs, IAM Identity Center instance/principal IDs, platform state role
ARNs, and the central state bucket name are outputs of the staged Terraform
roots. Keep real values in ignored `*.tfvars` files.

`joewegner.com` remains at its existing external DNS provider. Custom names are
reviewed for conflicts and created manually by the platform owner.
