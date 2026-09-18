# Migration runbook

## Safety snapshot

```bash
aws sts get-caller-identity
terraform -chdir=terraform/shared state pull > shared-pre-migration.tfstate
aws s3api list-buckets --query 'Buckets[].Name'
aws dynamodb list-tables --region us-east-1
aws lambda list-functions --region us-east-1
aws apigatewayv2 get-apis --region us-east-1
aws cloudfront list-distributions
aws cognito-idp list-user-pools --max-results 60 --region us-east-1
```

Store state and data backups outside the repository. Enable point-in-time
recovery or take on-demand DynamoDB backups before stateful migrations. Record
S3 version IDs for mutable data and deployment artifacts.

## Staged account bootstrap

1. Plan and apply `terraform/management` from account `743837809639`.
2. Verify root MFA, contacts, member-account access roles, and break-glass access.
3. Enable IAM Identity Center and apply assignments.
4. Assume the platform account bootstrap role and apply `terraform/platform`.
5. Assume each workload account role and apply `terraform/workload-bootstrap`.
6. Leave DNS authority at the existing provider. For each custom domain, add
   the ACM validation CNAME, wait for issuance, enable the CloudFront alias,
   then add the application CNAME to the CloudFront output.

## Weather development canary

1. Back up its old Terraform state and record all resource IDs.
2. Initialize the new tenant-prefixed backend with `npm run terraform:init`.
3. Import resources only when AWS supports moving them; resources cannot move
   across accounts through `terraform state mv` alone. Recreate stateless dev
   Lambda/API resources deliberately in `joe-workload`.
4. Review the plan for unexpected deletion or production changes.
5. Deploy, invoke each API, and verify logs remain in `joe-workload`.
6. Run negative access checks from Scott's session.
7. Keep old dev resources until the new environment passes acceptance.

Rollback before cutover deletes only newly created canary resources and restores
the old state as source of truth. For production DNS, restore the old alias and
wait for TTL expiry before removing new resources.

## Stateful applications

For Todone and Truth or Dare, create a separate checklist covering DynamoDB
backup/export, destination table creation, data import, validation counts,
write freeze, final synchronization, DNS cutover, and reverse synchronization.
Do not mark their migration complete based only on Terraform state operations.
