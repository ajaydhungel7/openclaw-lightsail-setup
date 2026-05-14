# ── IAM Role for Amazon Bedrock ───────────────────────────────────────────────
# Runs scripts/setup-bedrock-role.sh locally after the instance is up.
# The script reads the EC2 instance ID from the Lightsail support code and
# creates (or updates) an IAM role named LightsailRoleFor-<instance-id>.
#
# Note: this role is not tracked in Terraform state.
# To remove it: aws iam delete-role-policy / aws iam delete-role manually.

resource "null_resource" "bedrock_role" {
  count      = var.create_bedrock_role ? 1 : 0
  depends_on = [null_resource.wait_for_running]

  triggers = {
    instance_name = aws_lightsail_instance.openclaw.name
    region        = var.aws_region
  }

  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/setup-bedrock-role.sh ${aws_lightsail_instance.openclaw.name} ${var.aws_region}"
  }
}
