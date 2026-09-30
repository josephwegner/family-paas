mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "111122223333"
    }
  }

}

override_data {
  target = data.aws_iam_policy_document.tenant_trust
  values = {
    json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
  }
}

variables {
  platform_account_id = "111122223333"
  state_bucket_name   = "family-paas-terraform-state-test"
  tenants = {
    joe = {
      workload_account_id    = "444455556666"
      workload_principal_arn = "arn:aws:iam::444455556666:role/JoeWorkload"
    }
    scott = {
      workload_account_id    = "777788889999"
      workload_principal_arn = "arn:aws:iam::777788889999:role/ScottWorkload"
    }
    shared-services = {
      workload_account_id    = "222233334444"
      workload_principal_arn = "arn:aws:iam::222233334444:role/SharedServicesOperator"
    }
  }
}

run "tenant_policies_are_scoped" {
  command = plan

  assert {
    condition     = output.tenant_policy_scope["joe"].state_object_key_patterns[0] == "tenants/joe/*"
    error_message = "Joe's state policy must include only Joe's tenant prefix."
  }

  assert {
    condition     = output.tenant_policy_scope["shared-services"].state_object_key_patterns[0] == "tenants/shared-services/*"
    error_message = "Shared-services state must include only its own tenant prefix."
  }

  assert {
    condition     = !contains(output.tenant_policy_scope["shared-services"].state_list_prefixes, "tenants/joe") && !contains(output.tenant_policy_scope["shared-services"].state_list_prefixes, "tenants/scott")
    error_message = "Shared-services must not include a person tenant prefix."
  }

  assert {
    condition     = !contains(output.tenant_policy_scope["joe"].state_list_prefixes, "tenants/shared-services") && !contains(output.tenant_policy_scope["scott"].state_list_prefixes, "tenants/shared-services")
    error_message = "Person tenants must not include the shared-services prefix."
  }

  assert {
    condition     = !contains(output.tenant_policy_scope["joe"].state_list_prefixes, "tenants/scott")
    error_message = "Joe's state policy must not include Scott's prefix."
  }

}
