output "private_key_file" {
  description = "Path to the generated SSH private key (openclaw.pem) — keep this safe"
  value       = local_sensitive_file.openclaw_pem.filename
}

output "instance_name" {
  description = "Name of the OpenClaw Lightsail instance"
  value       = aws_lightsail_instance.openclaw.name
}

output "instance_arn" {
  description = "ARN of the OpenClaw Lightsail instance"
  value       = aws_lightsail_instance.openclaw.arn
}

output "public_ip" {
  description = "Public IP address of the instance (ephemeral — changes on stop/start unless static IP is attached)"
  value       = aws_lightsail_instance.openclaw.public_ip_address
}

output "static_ip" {
  description = "Static IP address attached to the instance (if enabled)"
  value       = var.create_static_ip ? aws_lightsail_static_ip.openclaw[0].ip_address : null
}

output "dashboard_url" {
  description = "URL for the OpenClaw dashboard (accessible after browser pairing)"
  value       = var.create_static_ip ? "https://${aws_lightsail_static_ip.openclaw[0].ip_address}" : "https://${aws_lightsail_instance.openclaw.public_ip_address}"
}

output "bedrock_role_setup" {
  description = "Whether the Bedrock IAM role setup script was run"
  value       = var.create_bedrock_role ? "completed" : "skipped"
}
