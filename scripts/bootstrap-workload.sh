#!/bin/bash
set -euo pipefail

if [ "$#" -ne 5 ]; then
  echo "Usage: npm run bootstrap:workload -- <tenant-id> <workload-account-id> <aws-profile> <state-bucket> <state-role-arn>"
  exit 1
fi

TENANT_ID="$1"
WORKLOAD_ACCOUNT_ID="$2"
AWS_PROFILE_NAME="$3"
STATE_BUCKET="$4"
STATE_ROLE_ARN="$5"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
TERRAFORM_DIR="${ROOT_DIR}/terraform/workload-bootstrap"
PLAN_FILE="$(mktemp "${TMPDIR:-/tmp}/family-paas-${TENANT_ID}-bootstrap.XXXXXX.tfplan")"

trap 'rm -f "$PLAN_FILE"' EXIT

if [[ ! "$TENANT_ID" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
  echo "Error: tenant ID must contain only lowercase letters, numbers, and hyphens."
  exit 1
fi

if [[ ! "$WORKLOAD_ACCOUNT_ID" =~ ^[0-9]{12}$ ]]; then
  echo "Error: workload account ID must be exactly 12 digits."
  exit 1
fi

if [[ ! "$STATE_ROLE_ARN" =~ ^arn:aws:iam::[0-9]{12}:role/.+ ]]; then
  echo "Error: state role ARN is not a valid IAM role ARN."
  exit 1
fi

if ! command -v aws >/dev/null; then
  echo "Error: AWS CLI is not installed."
  exit 1
fi

if ! command -v terraform >/dev/null; then
  echo "Error: Terraform is not installed."
  exit 1
fi

echo "Verifying AWS profile ${AWS_PROFILE_NAME}..."
ACTUAL_ACCOUNT_ID="$(AWS_PROFILE="$AWS_PROFILE_NAME" aws sts get-caller-identity --query Account --output text)"
if [ "$ACTUAL_ACCOUNT_ID" != "$WORKLOAD_ACCOUNT_ID" ]; then
  echo "Error: profile ${AWS_PROFILE_NAME} resolves to ${ACTUAL_ACCOUNT_ID}, expected ${WORKLOAD_ACCOUNT_ID}."
  exit 1
fi

echo "Initializing bootstrap state for tenant ${TENANT_ID}..."
AWS_PROFILE="$AWS_PROFILE_NAME" terraform -chdir="$TERRAFORM_DIR" init \
  -reconfigure \
  -backend-config="bucket=${STATE_BUCKET}" \
  -backend-config="key=tenants/${TENANT_ID}/bootstrap/terraform.tfstate" \
  -backend-config="region=us-east-1" \
  -backend-config="assume_role={role_arn=\"${STATE_ROLE_ARN}\"}" \
  -backend-config="encrypt=true" \
  -backend-config="use_lockfile=true"

echo "Creating workload bootstrap plan..."
AWS_PROFILE="$AWS_PROFILE_NAME" terraform -chdir="$TERRAFORM_DIR" plan \
  -var="workload_account_id=${WORKLOAD_ACCOUNT_ID}" \
  -out="$PLAN_FILE"

echo "Review the plan above before continuing."
read -r -p "Apply this workload bootstrap plan? Type yes to continue: " CONFIRMATION
if [ "$CONFIRMATION" != "yes" ]; then
  echo "Bootstrap cancelled. No resources were changed."
  exit 1
fi

echo "Applying the reviewed plan..."
AWS_PROFILE="$AWS_PROFILE_NAME" terraform -chdir="$TERRAFORM_DIR" apply "$PLAN_FILE"

echo "Workload account ${WORKLOAD_ACCOUNT_ID} is bootstrapped for tenant ${TENANT_ID}."
