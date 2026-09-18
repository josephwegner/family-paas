output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.id
}

output "tenant_registry" {
  value = {
    for tenant_id, tenant in local.tenant_registry : tenant_id => {
      workload_account_id = tenant.workload_account_id
      state_prefix        = tenant.state_prefix
      state_role_arn      = aws_iam_role.tenant_state[tenant_id].arn
    }
  }
}

output "tenant_policy_scope" {
  value = {
    for tenant_id, tenant in local.tenant_registry : tenant_id => {
      state_object_key_patterns = ["${tenant.state_prefix}/*"]
      state_list_prefixes       = [tenant.state_prefix, "${tenant.state_prefix}/*"]
    }
  }
}
