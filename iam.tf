# ── IAM Role for Amazon Bedrock ───────────────────────────────────────────────
# Replicates what the Lightsail console CloudShell script does.
# Role name must match what the OpenClaw blueprint writes to /home/ubuntu/.aws/config:
#   LightsailRoleFor-<ec2-instance-id>
#
# Trust policy: the instance assumes this role via EC2 instance metadata (IMDSv2).
# The principal is the AmazonLightsailInstance role that Lightsail assigns to all
# instances — scoped to the specific instance ID.
#
# Note: arn:aws:sts::<account>:assumed-role/AmazonLightsailInstance/<instance-id>
# is not valid as a principal at role creation time (it's a session, not an entity).
# The correct principal is the IAM role itself: AmazonLightsailInstance.

data "aws_caller_identity" "current" {}

resource "aws_iam_role" "openclaw_bedrock" {
  count = var.create_bedrock_role && var.ec2_instance_id != "" ? 1 : 0
  name  = "LightsailRoleFor-${var.ec2_instance_id}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowLightsailInstanceAssumeRole"
        Effect = "Allow"
        Principal = {
          # AmazonLightsailInstance lives in the AWS-managed Lightsail account (474668381803),
          # not in the user's account. This is the role all Lightsail instances use to
          # assume roles in the customer account via cross-account trust.
          # Scoped to the specific instance ID via Condition.
          AWS = "arn:aws:iam::474668381803:role/AmazonLightsailInstance"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringLike = {
            "aws:userid" = "*:${var.ec2_instance_id}"
          }
        }
      }
    ]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "openclaw_bedrock" {
  count = var.create_bedrock_role && var.ec2_instance_id != "" ? 1 : 0
  name  = "OpenClawBedrockPolicy"
  role  = aws_iam_role.openclaw_bedrock[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "BedrockAccess"
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream",
          "bedrock:ListFoundationModels",
          "bedrock:GetFoundationModel"
        ]
        Resource = "*"
      },
      {
        Sid    = "MarketplaceAccess"
        Effect = "Allow"
        Action = [
          "aws-marketplace:Subscribe",
          "aws-marketplace:Unsubscribe",
          "aws-marketplace:ViewSubscriptions"
        ]
        Resource = "*"
      }
    ]
  })
}
