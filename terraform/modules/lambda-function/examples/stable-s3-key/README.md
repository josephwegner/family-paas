# Stable S3 key fixture

This fixture verifies deployment changes when an application overwrites a ZIP
at the same S3 key.

1. Upload the first ZIP to the configured `s3_key`, calculate its base64 raw
   SHA-256, and apply this fixture:

   ```bash
   terraform init
   terraform apply \
     -var='app_name=example' \
     -var='lambda_role_arn=arn:aws:iam::123456789012:role/example-lambda' \
     -var='s3_bucket=lambda-deployments-123456789012' \
     -var='source_code_hash=FIRST_BASE64_SHA256'
   ```

2. Record the `version` output. Overwrite the ZIP at the **same** `s3_key`,
   calculate the new hash, and apply again with only `source_code_hash`
   changed. Terraform plans an in-place `aws_lambda_function` code update;
   because the module has `publish = true`, its `version` output becomes a new
   immutable version and the `live_alias_arn` alias points to it.

3. Run the identical apply once more. Terraform reports no changes. The earlier
   numbered version remains in Lambda and can be used for alias-based rollback.

Generate each input value from the exact ZIP being uploaded:

```bash
openssl dgst -sha256 -binary dist/lambdas/session.zip | base64
```
