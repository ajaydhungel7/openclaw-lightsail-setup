IP     := $(shell terraform output -raw static_ip 2>/dev/null)
KEY    := ./openclaw.pem
USER   := ubuntu
VAULT  := ansible/vars.yml

SSH    := ssh -i $(KEY) $(USER)@$(IP)
PLAY   := ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook -i "$(IP)," --private-key $(KEY) -u $(USER)
VARS   := \
  -e "telegram_bot_token=$(shell grep telegram_bot_token terraform.tfvars | cut -d'"' -f2 | xargs)" \
  -e "telegram_user_id=$(shell grep telegram_user_id terraform.tfvars | cut -d'"' -f2 | xargs)" \
  -e "notion_token=$(shell grep notion_token terraform.tfvars | cut -d'"' -f2 | xargs)"

# ── Infrastructure ────────────────────────────────────────────────────────────

apply:
	terraform apply

destroy:
	terraform destroy

# ── Post-deploy manual steps ──────────────────────────────────────────────────

## Step 1 — open dashboard in browser
dashboard:
	open https://$(IP)

## Step 2 — approve browser pairing (run after connecting in dashboard)
approve:
	$(PLAY) ansible/approve_device.yml

## Step 3 — re-run full configuration (idempotent, safe to re-run anytime)
configure:
	$(PLAY) $(VARS) ansible/configure_openclaw.yml

## Step 4 — Google (gog): one-time OAuth setup for Gmail, Calendar, Drive
## Prerequisites: download OAuth client JSON from Google Cloud Console first
## Usage: make gog-auth GOG_CREDS=~/Downloads/client_secret_*.json EMAIL=you@gmail.com
gog-auth:
	@test -n "$(GOG_CREDS)" || (echo "Usage: make gog-auth GOG_CREDS=~/Downloads/client_secret_*.json EMAIL=you@gmail.com" && exit 1)
	@test -n "$(EMAIL)" || (echo "Usage: make gog-auth GOG_CREDS=~/Downloads/client_secret_*.json EMAIL=you@gmail.com" && exit 1)
	scp -i $(KEY) $(GOG_CREDS) $(USER)@$(IP):~/gcp-oauth.json
	$(SSH) "gog auth credentials ~/gcp-oauth.json"
	@echo ""
	@echo "Step 1: Getting auth URL..."
	$(SSH) "gog auth add $(EMAIL) --services gmail,calendar,drive --remote --step 1"
	@echo ""
	@echo "Open the URL above in your browser, authorize, then copy the full redirect URL."
	@read -p "Paste the redirect URL here: " AUTH_URL && \
		$(SSH) "GOG_KEYRING_PASSWORD=openclaw gog auth add $(EMAIL) --services gmail,calendar,drive --remote --step 2 --auth-url '$$AUTH_URL'"
	$(SSH) "openclaw gateway restart"
	@echo "gog auth complete — Gmail, Calendar and Drive are ready."

# ── Useful shortcuts ──────────────────────────────────────────────────────────

ssh:
	$(SSH)

agents:
	$(SSH) "openclaw agents list"

skills:
	$(SSH) "openclaw skills list"

status:
	$(SSH) "openclaw gateway status && openclaw mcp list"

logs:
	$(SSH) "tail -f /tmp/openclaw/openclaw-$(shell date +%Y-%m-%d).log"

token:
	$(SSH) "jq -r '.gateway.auth.token' ~/.openclaw/openclaw.json"

restart:
	$(SSH) "openclaw gateway restart"

.PHONY: apply destroy dashboard approve configure gog-auth ssh status agents logs token restart
