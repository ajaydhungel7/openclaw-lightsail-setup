# Notion Setup

OpenClaw uses Notion as a personal database for tasks and notes. The setup is a one-time process — once done, everything works automatically on every deploy.

## 1. Create a Notion integration

1. Go to [notion.so/profile/integrations](https://www.notion.so/profile/integrations)
2. Click **New integration**
3. Name it `OpenClaw`, set type to **Internal**
4. Copy the token — it starts with `ntn_****`
5. Add it to `terraform.tfvars`:
   ```
   notion_token = "ntn_****"
   ```

## 2. Create the OpenClaw page in Notion

1. Create a new page in your Notion workspace — name it `OpenClaw`
2. Open the page, click `...` → **Connections** → search for **OpenClaw** → connect it

This gives the integration permission to create and read content inside this page.

## 3. Create the databases

With the integration connected, run this script once to create the Tasks and Notes databases automatically:

```bash
NOTION_TOKEN="your_token_here"
PARENT_PAGE_ID="your_page_id_here"  # from the page URL: notion.so/OpenClaw-<page-id>

# Create Tasks database
curl -s https://api.notion.com/v1/databases \
  -H "Authorization: Bearer $NOTION_TOKEN" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{
    "parent": {"type": "page_id", "page_id": "'"$PARENT_PAGE_ID"'"},
    "icon": {"type": "emoji", "emoji": "✅"},
    "title": [{"type": "text", "text": {"content": "Tasks"}}],
    "properties": {
      "Title":    {"title": {}},
      "Status":   {"select": {"options": [{"name": "Not started", "color": "red"}, {"name": "In progress", "color": "yellow"}, {"name": "Done", "color": "green"}]}},
      "Due":      {"date": {}},
      "Priority": {"select": {"options": [{"name": "High", "color": "red"}, {"name": "Medium", "color": "yellow"}, {"name": "Low", "color": "blue"}]}},
      "Notes":    {"rich_text": {}}
    }
  }'

# Create Notes database
curl -s https://api.notion.com/v1/databases \
  -H "Authorization: Bearer $NOTION_TOKEN" \
  -H "Notion-Version: 2022-06-28" \
  -H "Content-Type: application/json" \
  -d '{
    "parent": {"type": "page_id", "page_id": "'"$PARENT_PAGE_ID"'"},
    "icon": {"type": "emoji", "emoji": "📝"},
    "title": [{"type": "text", "text": {"content": "Notes"}}],
    "properties": {
      "Title": {"title": {}},
      "Date":  {"date": {}},
      "Tags":  {"multi_select": {"options": [{"name": "meeting", "color": "blue"}, {"name": "idea", "color": "purple"}, {"name": "capture", "color": "gray"}]}}
    }
  }'
```

## How it works after setup

The agent searches for databases by name (`Tasks`, `Notes`) at runtime — no IDs to manage. The Notion MCP server is registered automatically via Ansible on every deploy.

## What the agent can do

- **Tasks**: query due today, add new tasks, mark done
- **Notes**: create meeting notes, quick captures, log anything

Example Telegram commands:
```
"What tasks do I have today?"
"Add a task: review the PR by Friday"
"Log a note from my standup: team is blocked on auth"
```
