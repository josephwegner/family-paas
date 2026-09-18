# Identity and authorization

Operators authenticate through IAM Identity Center with MFA-backed,
short-lived sessions. Each tenant is assigned to only its workload account and
may assume only its own platform state role.

Workload permissions support the services used by the application modules but
exclude organization administration, account administration, consolidated
billing, and arbitrary cross-account role assumption.

Application authentication is separate from AWS operator identity. The API
Gateway module can validate JWT issuer and audience. A valid JWT establishes
identity; handlers must still enforce authorization, including ownership,
tenant membership, role or scope, and access to the requested record.

Cross-account Cognito integration is not part of the current onboarding model.
