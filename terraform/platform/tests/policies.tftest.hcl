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
  }
}

run "tenant_policies_are_scoped" {
  command = plan

  assert {
    condition     = output.tenant_policy_scope["joe"].state_object_key_patterns[0] == "tenants/joe/*"
    error_message = "Joe's state policy must include only Joe's tenant prefix."
  }

  assert {
    condition     = !contains(output.tenant_policy_scope["joe"].state_list_prefixes, "tenants/scott")
    error_message = "Joe's state policy must not include Scott's prefix."
  }

}
