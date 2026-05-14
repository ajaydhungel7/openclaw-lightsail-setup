# Telegram Setup

Atlas communicates with you exclusively over Telegram. You need a bot token and your Telegram user ID before deploying.

## 1. Create a bot

1. Open Telegram and message [@BotFather](https://t.me/BotFather)
2. Send `/newbot`
3. Choose a name (e.g. `Atlas`) and a username (e.g. `atlas_yourname_bot`)
4. BotFather replies with a token — looks like `123456789:AAE...`
5. Add it to `terraform.tfvars`:
   ```
   telegram_bot_token = "123456789:AAE..."
   ```

## 2. Get your Telegram user ID

1. Message [@RawDataBot](https://t.me/RawDataBot) (or [@userinfobot](https://t.me/userinfobot))
2. It replies with your numeric user ID (e.g. `873698411`)
3. Add it to `terraform.tfvars`:
   ```
   telegram_user_id = "873698411"
   ```

## How it works after deploy

Ansible configures the Telegram channel automatically — it sets the bot token, restricts incoming messages to your user ID only, and binds the channel to the orchestrator agent.

Only messages from your Telegram user ID are accepted. Anyone else messaging the bot gets no response.

## Start chatting

Once deployed, open Telegram and message your bot. Atlas responds immediately.

If Atlas doesn't respond, check:
```bash
make logs    # tail gateway logs
make status  # verify Telegram channel is enabled
```
