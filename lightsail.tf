# ── Lightsail Instance ───────────────────────────────────────────────────────
# The OpenClaw blueprint is a pre-configured Linux/Unix image from AWS.
# 4 GB RAM (medium_3_0) is the recommended minimum for OpenClaw.

resource "aws_lightsail_instance" "openclaw" {
  name              = var.instance_name
  availability_zone = "${var.aws_region}a"
  blueprint_id      = "openclaw_ls_1_0"
  bundle_id         = var.bundle_id
  key_pair_name     = aws_lightsail_key_pair.openclaw.name

  tags = var.tags
}

# ── Wait for instance to be running ─────────────────────────────────────────
# The OpenClaw blueprint takes longer to initialize than a standard OS image.
# Lightsail rejects port and static IP operations while the instance is pending.

resource "null_resource" "wait_for_running" {
  depends_on = [aws_lightsail_instance.openclaw]

  provisioner "local-exec" {
    command = <<-EOF
      echo "Waiting for instance to reach running state..."
      for i in $(seq 1 30); do
        STATE=$(aws lightsail get-instance \
          --instance-name ${aws_lightsail_instance.openclaw.name} \
          --region ${var.aws_region} \
          --query 'instance.state.name' \
          --output text)
        echo "  State: $STATE"
        if [ "$STATE" = "running" ]; then
          echo "Instance is running."
          exit 0
        fi
        sleep 10
      done
      echo "Timed out waiting for instance to be running." && exit 1
    EOF
  }
}

# ── Firewall Rules ───────────────────────────────────────────────────────────
# 443 — HTTPS for the OpenClaw dashboard
# 80  — HTTP required for Let's Encrypt HTTP-01 challenge (cert issuance + renewal)
#       Without this, lightsail-manage-certd cannot issue a cert for the static IP,
#       causing Apache to repeatedly stop/start and dropping WebSocket connections.
# 22  — SSH, needed for browser pairing and instance management

resource "aws_lightsail_instance_public_ports" "openclaw" {
  depends_on    = [null_resource.wait_for_running]
  instance_name = aws_lightsail_instance.openclaw.name

  port_info {
    protocol  = "tcp"
    from_port = 443
    to_port   = 443
  }

  port_info {
    protocol  = "tcp"
    from_port = 80
    to_port   = 80
  }

  port_info {
    protocol  = "tcp"
    from_port = 22
    to_port   = 22
    cidrs     = var.ssh_allowed_cidrs
  }
}

# ── Static IP ────────────────────────────────────────────────────────────────
# Without a static IP, the public IP changes every time the instance is stopped
# and started — which would break the SSL cert and require re-pairing browsers.

resource "aws_lightsail_static_ip" "openclaw" {
  count = var.create_static_ip ? 1 : 0
  name  = "${var.instance_name}-static-ip"
}

resource "aws_lightsail_static_ip_attachment" "openclaw" {
  count          = var.create_static_ip ? 1 : 0
  depends_on     = [null_resource.wait_for_running]
  static_ip_name = aws_lightsail_static_ip.openclaw[0].id
  instance_name  = aws_lightsail_instance.openclaw.id
}
