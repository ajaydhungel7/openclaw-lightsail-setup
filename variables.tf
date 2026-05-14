variable "aws_region" {
  description = "AWS region to deploy the Lightsail instance"
  type        = string
  default     = "us-east-1"
}

variable "instance_name" {
  description = "Name for the Lightsail OpenClaw instance"
  type        = string
  default     = "openclaw"
}

variable "bundle_id" {
  description = <<-EOT
    Lightsail instance bundle (plan). 4 GB RAM is recommended for OpenClaw.
    Common Linux/Unix options:
      nano_3_0   → 512 MB RAM,  1 vCPU,  20 GB SSD
      micro_3_0  → 1 GB RAM,   1 vCPU,  40 GB SSD
      small_3_0  → 2 GB RAM,   1 vCPU,  60 GB SSD
      medium_3_0 → 4 GB RAM,   2 vCPU,  80 GB SSD  ← recommended
      large_3_0  → 8 GB RAM,   2 vCPU, 160 GB SSD
  EOT
  type        = string
  default     = "medium_3_0"
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed to reach port 22. Restrict to your IP for better security."
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "create_static_ip" {
  description = "Attach a static IP to the instance (recommended — prevents IP change on stop/start)"
  type        = bool
  default     = true
}

variable "create_bedrock_role" {
  description = "Create the IAM role granting the instance access to Amazon Bedrock APIs"
  type        = bool
  default     = true
}

variable "ec2_instance_id" {
  description = "Underlying EC2 instance ID of the Lightsail instance (e.g. i-0eec813f38578756a). Used to name the Bedrock IAM role to match what the OpenClaw blueprint expects in /home/ubuntu/.aws/config."
  type        = string
  default     = ""
}

variable "telegram_bot_token" {
  description = "Telegram bot token from BotFather"
  type        = string
  sensitive   = true
}

variable "telegram_user_id" {
  description = "Your Telegram user ID (get it from @userinfobot)"
  type        = string
  sensitive   = true
}

variable "notion_token" {
  description = "Notion internal integration token (ntn_****) from notion.so/profile/integrations"
  type        = string
  sensitive   = true
}


variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Project = "openclaw"
  }
}
