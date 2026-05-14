# ── Run Ansible playbook after infrastructure is ready ───────────────────────
# local-exec runs on your local machine and invokes ansible-playbook,
# which SSHes into the instance to configure OpenClaw.

resource "null_resource" "ansible_configure" {
  depends_on = [
    aws_lightsail_instance_public_ports.openclaw,
    aws_lightsail_static_ip_attachment.openclaw,
    local_sensitive_file.openclaw_pem,
  ]

  provisioner "local-exec" {
    command = <<-EOF
      ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook \
        -i "${var.create_static_ip ? aws_lightsail_static_ip.openclaw[0].ip_address : aws_lightsail_instance.openclaw.public_ip_address}," \
        --private-key "${local_sensitive_file.openclaw_pem.filename}" \
        -u ubuntu \
        -e "telegram_bot_token=${var.telegram_bot_token}" \
        -e "telegram_user_id=${var.telegram_user_id}" \
        -e "notion_token=${var.notion_token}" \
        ${path.module}/ansible/configure_openclaw.yml
    EOF
  }
}
