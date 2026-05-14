#!/bin/bash
# Creates the IAM role that allows an OpenClaw Lightsail instance to call Amazon Bedrock.
# Usage: bash scripts/setup-bedrock-role.sh <lightsail-instance-name> [region]
#
# Sourced from the official OpenClaw setup script. Vendored here so the deploy
# does not depend on an external URL.

export AWS_PAGER=""

set -e

on_error() {
  echo ""
  echo "  Something went wrong."
  echo "  - Instance name used: ${INSTANCE_NAME} — verify this is correct."
  echo "  - Region used:        ${REGION} — verify this is correct."
  echo "  - Verify your AWS credentials have: iam:CreateRole, iam:PutRolePolicy,"
  echo "    iam:UpdateAssumeRolePolicy, iam:GetRole, lightsail:GetInstance"
  echo ""
}
trap on_error ERR

INSTANCE_NAME="${1:?Usage: $0 <lightsail-instance-name> [region]}"
REGION="${2:-us-east-1}"

echo "Setting up Bedrock IAM role..."
echo "  Instance: $INSTANCE_NAME"
echo "  Region:   $REGION"

SUPPORT_CODE=$(aws lightsail get-instance \
  --instance-name "$INSTANCE_NAME" \
  --region "$REGION" \
  --query "instance.supportCode" \
  --output text)

if [[ -z "$SUPPORT_CODE" || "$SUPPORT_CODE" == "None" || "$SUPPORT_CODE" != */* ]]; then
  echo "Error: could not retrieve a valid support code for instance '$INSTANCE_NAME'."
  exit 1
fi

LIGHTSAIL_ACCOUNT=$(echo "$SUPPORT_CODE" | cut -d'/' -f1)
INSTANCE_ID=$(echo "$SUPPORT_CODE" | cut -d'/' -f2)
ROLE_NAME="LightsailRoleFor-${INSTANCE_ID}"

echo "  EC2 instance ID: $INSTANCE_ID"
echo "  IAM role name:   $ROLE_NAME"

TRUST_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:sts::${LIGHTSAIL_ACCOUNT}:assumed-role/AmazonLightsailInstance/${INSTANCE_ID}"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
)

PERMISSIONS_POLICY=$(cat <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "BedrockInvoke",
      "Effect": "Allow",
      "Action": [
        "bedrock:ListFoundationModels",
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream"
      ],
      "Resource": "*"
    },
    {
      "Sid": "MarketplaceModelAccess",
      "Effect": "Allow",
      "Action": [
        "aws-marketplace:Subscribe",
        "aws-marketplace:Unsubscribe",
        "aws-marketplace:ViewSubscriptions"
      ],
      "Resource": "*"
    }
  ]
}
EOF
)

if aws iam get-role --role-name "$ROLE_NAME" &>/dev/null; then
  echo "  Role already exists — updating trust policy..."
  aws iam update-assume-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-document "$TRUST_POLICY"
else
  echo "  Creating role..."
  aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document "$TRUST_POLICY" \
    --description "Allows OpenClaw on Lightsail instance $INSTANCE_NAME to access Bedrock"
fi

aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name "OpenClawBedrockAccess" \
  --policy-document "$PERMISSIONS_POLICY"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo ""
echo "Bedrock role ready."
echo "  ARN: arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
