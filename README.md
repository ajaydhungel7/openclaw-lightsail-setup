# OpenClaw on AWS Lightsail

Deploy a private AI personal assistant on AWS Lightsail in one command. Built on [OpenClaw](https://openclaw.ai) with Terraform + Ansible — fully automated, version-controlled, reproducible.

## What it does

A personal assistant called **Atlas** runs on your own AWS instance and is accessible via Telegram. It connects to Gmail, Google Calendar, Notion, and weather — and sends you a morning briefing every day.

```
You (Telegram)
      │
      ▼
 Atlas 🧭 (Orchestrator)
      │
      ├──► gog CLI     → Gmail · Google Calendar · Drive
      ├──► Notion MCP  → Tasks · Notes
      └──► weather     → forecast
```

### What Atlas can do

| Ask Atlas | What happens |
|-----------|-------------|
| "Do I have any meetings today?" | Checks Google Calendar |
| "Any important emails?" | Searches Gmail for unread |
| "Did I get an email about [topic]?" | Gmail search |
| "Add a task: [thing]" | Creates entry in Notion Tasks |
| "What's due today?" | Queries Notion Tasks |
| "Log a note: [thing]" | Creates entry in Notion Notes |
| "Prep me for my 3pm meeting" | Calendar event + emails from attendees |
| "What's the weather?" | Current forecast |
| Every morning at 7am | Sends briefing: weather + calendar + email + tasks |

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/) >= 2.14
- [AWS CLI](https://aws.amazon.com/cli/) configured (`aws configure`)
- A **Telegram bot** — create one via [@BotFather](https://t.me/BotFather) on Telegram
- Your **Telegram user ID** — get it from [@userinfobot](https://t.me/userinfobot)
- A **Notion account** — see [docs/notion-setup.md](docs/notion-setup.md)
- A **Google account** with a Cloud project — see [docs/google-setup.md](docs/google-setup.md)

### AWS permissions required

Your AWS user needs:
- `AmazonLightsailFullAccess`
- `IAMFullAccess` (to create the Bedrock role)

---

## Quick start

### 1. Clone and configure

```bash
git clone https://github.com/ajaydhungel7/openclaw-lightsail-setup
cd openclaw-lightsail-setup

cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars and fill in your values
```

### 2. Deploy

```bash
terraform init
terraform apply
```

This provisions the Lightsail instance, static IP, firewall, and Bedrock IAM role, then automatically runs Ansible to configure OpenClaw, register agents, install skills, and set up Telegram.

Takes ~5–10 minutes. At the end, Ansible prints the dashboard URL and token.

### 3. Connect your browser

```bash
make dashboard   # opens https://<your-ip>
```

Enter the WebSocket URL (`wss://<ip>`) and token from the Ansible output, click Connect.

```bash
make approve     # approves the browser pairing
```

### 4. Set up Google auth (one-time)

Follow [docs/google-setup.md](docs/google-setup.md) to create a Google Cloud project and download your OAuth credentials, then:

```bash
make gog-auth GOG_CREDS=~/Downloads/client_secret_*.json EMAIL=you@gmail.com
```

### 5. Set up Notion (one-time)

Follow [docs/notion-setup.md](docs/notion-setup.md) to create the integration and databases.

### 6. Start chatting

Open Telegram, message your bot. Atlas is ready.

---

## How it works

### Infrastructure (Terraform)

| File | What it does |
|------|-------------|
| `keypair.tf` | Generates RSA key pair, saves `openclaw.pem` locally |
| `lightsail.tf` | Creates instance (4GB), firewall (22/80/443), static IP |
| `iam.tf` | Creates IAM role granting the instance access to Amazon Bedrock |
| `ansible.tf` | Triggers Ansible via `local-exec` after infrastructure is ready |
| `versions.tf` | Terraform + provider version pins |

### Configuration (Ansible)

`ansible/configure_openclaw.yml` runs automatically after `terraform apply`:

1. Waits for the gateway to start
2. Waits for TLS certificate (Let's Encrypt via `lightsail-manage-certd`)
3. Fixes Apache WebSocket proxying
4. Configures gateway (loopback mode, allowed origins)
5. Installs `gog` (Google Workspace CLI)
6. Registers Notion MCP server
7. Deploys agent workspace files
8. Configures Telegram channel and bindings
9. Disables sandbox, sets tool execution permissions
10. Sets `GOG_KEYRING_PASSWORD` for token decryption
11. Restarts gateway

`ansible/approve_device.yml` — run once after connecting in the dashboard to approve the browser device.

### Agents

Agents live in `ansible/files/openclaw/workspace/`. Each agent has:

- `AGENTS.md` — what the agent does and how it behaves
- `SOUL.md` — communication style
- `IDENTITY.md` — name and emoji

| Agent | Role |
|-------|------|
| `orchestrator/` | Atlas 🧭 — receives Telegram messages, calls gog + Notion + weather directly |

`USER.md` at the workspace root sets communication preferences applied to all agents.

---

## Make commands

```bash
make apply        # terraform apply
make destroy      # terraform destroy

make configure    # re-run Ansible (idempotent, safe to run anytime)
make approve      # approve browser device pairing
make dashboard    # open dashboard in browser

make gog-auth GOG_CREDS=<file> EMAIL=<email>   # one-time Google OAuth

make ssh          # SSH into the instance
make agents       # list configured agents
make skills       # list available skills and their status
make status       # gateway status + MCP servers
make logs         # tail live gateway logs
make token        # print gateway auth token
make restart      # restart the gateway
```

---

## Customising your assistant

### Change the agents' behaviour

Edit the files in `ansible/files/openclaw/workspace/`, then re-run:

```bash
make configure
```

The key files:
- `orchestrator/AGENTS.md` — routing logic and tool usage
- `orchestrator/HEARTBEAT.md` — morning briefing schedule and steps
- `USER.md` — your communication preferences

### Change the model

Default is `claude-sonnet-4-6` via Amazon Bedrock. To change, update the model in `openclaw.json` on the server or via the dashboard.

### Add more skills

```bash
make ssh
openclaw skills list     # see all available skills
openclaw skills install <slug>   # install from ClawHub
```

---

## Costs

| Resource | Cost |
|----------|------|
| Lightsail `medium_3_0` (4GB) | ~$20/month |
| Static IP | Free while attached |
| Amazon Bedrock | Pay per token (Claude Sonnet ~$3/1M input tokens) |
| **Total** | ~$20–25/month typical |
