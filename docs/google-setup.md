# Google Setup

OpenClaw uses the `gog` CLI to access Gmail, Google Calendar, and Google Drive. This requires a one-time OAuth setup via a Google Cloud project.

## 1. Create a Google Cloud project

1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Click the project dropdown → **New Project**
3. Name it `openclaw` → **Create**

## 2. Enable APIs

In the search bar, enable each of these:
- **Gmail API**
- **Google Calendar API**
- **Google Drive API**

## 3. Configure OAuth consent screen

1. Left menu → **APIs & Services** → **OAuth consent screen** (or **Google Auth Platform**)
2. Choose **External** → **Create**
3. Fill in app name (`OpenClaw`) and your email
4. Click through the steps — no scopes needed here
5. On **Audience** → add your Gmail address as a test user

## 4. Create OAuth credentials

1. Left menu → **Credentials** → **+ Create Credentials** → **OAuth client ID**
2. Application type: **Desktop app**
3. Name: `openclaw-gog`
4. **Create** → **Download JSON** — save this file

## 5. Run gog auth

After `terraform apply` completes:

```bash
make gog-auth GOG_CREDS=~/Downloads/client_secret_*.json EMAIL=you@gmail.com
```

This will:
1. Copy your credentials to the server
2. Print an auth URL — open it in your browser
3. Authorize with Google — you'll be redirected to a localhost URL that won't load (expected)
4. Copy the full redirect URL from the browser address bar
5. Paste it into the terminal when prompted

The token is stored on the server and persists across gateway restarts. It also survives `terraform destroy` + `terraform apply` if you run `gog-auth` again after each fresh deploy.

## What the agent can do

Once authenticated, Atlas can:

- **Gmail**: search emails, read threads, draft replies
- **Calendar**: list today's events, check upcoming meetings, prep for calls
- **Drive**: search and read documents

Example Telegram commands:
```
"Do I have any meetings today?"
"Did I get an email from [name]?"
"Prep me for my 3pm meeting"
"Check if I got any emails about [topic]"
```

## Notes

- The OAuth token uses `GOG_KEYRING_PASSWORD=openclaw` for the keyring backend — this is set automatically in the gateway environment via Ansible
- The credentials JSON stays on the server at `~/gcp-oauth.json` — keep it private
- If the token expires or you see auth errors, re-run `make gog-auth`
