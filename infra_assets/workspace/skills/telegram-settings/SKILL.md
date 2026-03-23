---
name: telegram-settings
description: Use when asked to change Telegram channel settings such as group policy, DM policy, allowed users, or streaming mode. Also use when troubleshooting why the bot does not respond in groups or DMs.
---

# Telegram Settings (Self-Service)

This skill lets you inspect and update your own Telegram channel configuration and restart yourself to apply changes. All edits happen on the live config file; you have shell access and Docker socket access.

## File Locations

| What | Path |
|------|------|
| Live config (inside container) | `/home/node/.openclaw/openclaw.json` |
| Live config (host path) | `/root/.openclaw/openclaw.json` |
| Repo source of truth | `openclaw-infra/config/openclaw.json` in `my_openclaw` repo |

**Important:** Edits to the live config are immediate but will be overwritten on the next deploy. After making an emergency live edit, remind Andre to backport the change to the repo.

## Telegram Channel Settings

All Telegram settings live under `channels.telegram` in `openclaw.json`.

### groupPolicy

Controls whether the bot responds in Telegram group chats.

| Value | Behavior |
|-------|----------|
| `"disabled"` | Ignores all group messages |
| `"open"` | Responds in any group the bot is added to |
| `"allowlist"` | Only responds in groups listed in the `groups` array |

If set to `"allowlist"`, you also need a `groups` array with allowed group chat IDs:
```json
"groupPolicy": "allowlist",
"groups": [-1001234567890]
```

### dmPolicy

Controls who can message the bot in DMs.

| Value | Behavior |
|-------|----------|
| `"open"` | Anyone can DM the bot |
| `"allowlist"` | Only user IDs in the `allowFrom` array can DM the bot |

### allowFrom

Array of Telegram user IDs allowed to DM the bot (when `dmPolicy` is `"allowlist"`).

```json
"allowFrom": [876499264]
```

### streaming

Controls how bot responses are streamed in Telegram.

| Value | Behavior |
|-------|----------|
| `"partial"` | Stream partial updates (edits the message as it generates) |
| `"full"` | Send the complete response as a single message |
| `"disabled"` | No streaming |

## How to Inspect Current Settings

```bash
cat /home/node/.openclaw/openclaw.json | jq '.channels.telegram'
```

## How to Change a Setting

Use `jq` to update the live config file in place. Examples:

**Enable group chat:**
```bash
jq '.channels.telegram.groupPolicy = "open"' /home/node/.openclaw/openclaw.json > /tmp/oc-config.json && mv /tmp/oc-config.json /home/node/.openclaw/openclaw.json
```

**Disable group chat:**
```bash
jq '.channels.telegram.groupPolicy = "disabled"' /home/node/.openclaw/openclaw.json > /tmp/oc-config.json && mv /tmp/oc-config.json /home/node/.openclaw/openclaw.json
```

**Switch to group allowlist with specific group IDs:**
```bash
jq '.channels.telegram.groupPolicy = "allowlist" | .channels.telegram.groups = [-1001234567890]' /home/node/.openclaw/openclaw.json > /tmp/oc-config.json && mv /tmp/oc-config.json /home/node/.openclaw/openclaw.json
```

**Add a user to DM allowlist:**
```bash
jq '.channels.telegram.allowFrom += [123456789]' /home/node/.openclaw/openclaw.json > /tmp/oc-config.json && mv /tmp/oc-config.json /home/node/.openclaw/openclaw.json
```

**Open DMs to everyone:**
```bash
jq '.channels.telegram.dmPolicy = "open"' /home/node/.openclaw/openclaw.json > /tmp/oc-config.json && mv /tmp/oc-config.json /home/node/.openclaw/openclaw.json
```

## How to Apply Changes

After editing the config, restart the gateway so it picks up the new settings:

```bash
docker restart openclaw-gateway
```

Then verify the gateway is healthy:

```bash
sleep 10 && curl -sf http://127.0.0.1:18789/healthz && echo " OK" || echo " UNHEALTHY"
```

## Troubleshooting: Bot Not Responding in Groups

Check these in order:

1. **groupPolicy** — Must be `"open"` or `"allowlist"` (with the group ID listed). If `"disabled"`, the bot silently ignores all group messages.

2. **Telegram Privacy Mode** (BotFather setting) — If privacy mode is enabled, the bot only sees messages that start with `/` or `@mention` the bot. This is a Telegram API-level setting, not an OpenClaw setting. Andre must change it via @BotFather → /mybots → Bot Settings → Group Privacy → Turn off.

3. **Bot was removed and re-added** — Removing and re-adding the bot to a group can reset its permissions. The bot may need to be re-added as an admin or privacy mode toggled off again after re-adding.

4. **Bot admin status** — Some groups require bots to be admins to see all messages. Check with Andre if the bot has admin rights in the target group.

## Troubleshooting: Bot Not Responding in DMs

1. **dmPolicy** — Must be `"open"` or `"allowlist"` with the sender's user ID in `allowFrom`.
2. **Check the allowFrom array** for the sender's Telegram user ID.

## Reminder

Live config edits are emergency/convenience changes. Always remind Andre to backport changes to the `my_openclaw` repo (`openclaw-infra/config/openclaw.json` and `infra_assets/config/openclaw.json`) so the next deploy doesn't revert them.
