# ── SSH Key Pair ─────────────────────────────────────────────────────────────
# Terraform generates a key pair and registers the public key with Lightsail.
# The private key is saved as openclaw.pem in this directory (chmod 600).
# Add openclaw.pem to .gitignore — never commit it.

resource "tls_private_key" "openclaw" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_lightsail_key_pair" "openclaw" {
  name       = "${var.instance_name}-keypair"
  public_key = tls_private_key.openclaw.public_key_openssh
}

resource "local_sensitive_file" "openclaw_pem" {
  content         = tls_private_key.openclaw.private_key_pem
  filename        = "${path.module}/openclaw.pem"
  file_permission = "0600"
}
