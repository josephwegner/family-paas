# Pre-migration inventory

> **Historical deployment-specific record**
>
> Captured: 2026-09-18. This file describes resources observed before the
> migration and is not a statement of current architecture.

Captured from account `743837809639` before creating the AWS Organization.
Re-run the commands in `migration.md` immediately before each migration.

## Global resources

- No Route 53 hosted zones exist in this account. `joewegner.com` remains at
  its current external DNS provider.
- CloudFront aliases include `weather.joewegner.com`,
  `truthordare.joewegner.com`, `jort.app`, and `www.jort.app`.
- Cognito pools include `family-paas-users` and `todone-users-prod`; Cognito is
  explicitly excluded from the initial workload migration.

## Stateful resources

- S3 includes central state, Lambda packages, shared media, and application
  frontend buckets. Bucket versioning and object inventories must be captured
  separately before migration.
- DynamoDB tables: `shared-app-data`, `terraform-state-lock`,
  `todone-data-prod`, and `truthordare-dares-prod`.
- `todone` and `truthordare` are stateful and require application-specific data
  transfer and rollback plans.

## Compute inventory

- Weather has prod API/Lambda resources and dev Lambda resources.
- Truth or Dare has a prod API, Lambda resources, CloudFront, S3, and DynamoDB.
- Todone has a prod API, Lambda resources, S3, DynamoDB, and Cognito.

## Canary selection and outcome

The initial inventory suggested a development canary, but repository inspection
showed that only production was represented in Terraform. The production
`weather-app` stack became the canary. It was recreated in the workload account,
validated at its default endpoints, issued a workload-owned certificate, and
then received the external DNS cutover.
