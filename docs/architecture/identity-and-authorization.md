# Identity and authorization

Operators authenticate through IAM Identity Center with MFA-backed,
short-lived sessions. Each tenant is assigned to only its workload account and
may assume only its own platform state role.

Workload permissions support the services used by the application modules but
exclude organization administration, account administration, consolidated
billing, and arbitrary cross-account role assumption. Users can create SNS
topics, including topics with tags, in their own workload account in any region.
The topic-creation permission does not grant publishing or subscription access.

Household-appliance operators use a separate
`FamilyPaas-SharedSvc-Operator` permission set in `shared-services`. Assignment
is explicit and does not add shared-services access to a person's normal
workload permission set. The operator set may assume only the shared-services
platform state role.

Application authentication is separate from AWS operator identity. The API
Gateway module can validate JWT issuer and audience. A valid JWT establishes
identity; handlers must still enforce authorization, including ownership,
tenant membership, role or scope, and access to the requested record.

Cross-account Cognito integration is not part of the current onboarding model.
