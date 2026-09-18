# DNS and certificates

DNS remains at an external provider. Family-PaaS creates no Route 53 hosted
zone and grants tenants no DNS permissions.

Applications work at their default CloudFront hostname without custom DNS. To
add a custom hostname:

1. Configure `domain_name` and leave `enable_custom_domain = false`.
2. Apply Terraform. It requests a non-exportable ACM certificate in the
   workload account's `us-east-1` region.
3. Read `custom_domain_validation_records` and create those CNAME records at
   the external DNS provider.
4. Wait until ACM reports `ISSUED`.
5. Confirm no other CloudFront distribution owns the hostname.
6. Set `enable_custom_domain = true` and apply Terraform again.
7. Point the external application CNAME to `custom_domain_cname_target`.
8. Keep the ACM validation CNAME so automatic renewal continues.

For a cross-account CloudFront migration, release the alias from the old
distribution and wait for it to report `Deployed`. Point public DNS to the new
distribution before adding the alias there; CloudFront rejects aliases whose
DNS still points to another distribution.

Apex domains require a provider-specific ALIAS, ANAME, or CNAME-flattening
feature. Public hostnames remain discoverable through DNS, Certificate
Transparency logs, passive DNS, crawlers, and direct sharing.
