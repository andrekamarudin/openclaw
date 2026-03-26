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

### groups (per-group settings)

The `groups` object lets you configure per-group behavior. Use `"*"` as a wildcard key to set defaults for all groups.

#### requireMention

Controls whether the bot requires an @mention to respond in group chats.

| Value | Behavior |
|-------|----------|
| `true` | Bot only responds when @mentioned or replied to (default) |
| `false` | Bot responds to every message in the group |

**Priority order** (first defined wins):
1. Topic-specific override (`groups[chatId].topics[topicId].requireMention`)
2. Group-specific override (`groups[chatId].requireMention`)
3. Wildcard group default (`groups["*"].requireMention`)
4. OpenClaw built-in default (`true`)

Example — respond to all messages in all groups:
```json
"groups": {
  "*": {
    "requireMention": false
  }
}
```

### execApprovals

Controls whether exec commands are forwarded to Telegram for approval before running.

```json
"execApprovals": {
  "enabled": true,
  "approvers": [876499264],
  "target": "channel",
  "agentFilter": ["main"]
}
```

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

**Add a user to DM allowlist:**
```bash
jq '.channels.telegram.allowFrom += [123456789]' /home/node/.openclaw/openclaw.json > /tmp/oc-config.json && mv /tmp/oc-config.json /home/node/.openclaw/openclaw.json
```

**Respond to all messages (no @mention needed):**
```bash
jq '.channels.telegram.groups["*"].requireMention = false' /home/node/.openclaw/openclaw.json > /tmp/oc-config.json && mv /tmp/oc-config.json /home/node/.openclaw/openclaw.json
```

## How to Apply Changes

After editing the config, restart the gateway so it picks up the new settings:

```bash
curl --unix-socket /var/run/docker.sock -X POST "http://localhost/containers/openclaw-gateway/restart"
```

Then verify the gateway is healthy:

```bash
sleep 10 && curl -sf http://127.0.0.1:18789/healthz && echo " OK" || echo " UNHEALTHY"
```

## Troubleshooting: Bot Not Responding in Groups

Check these in order:

1. **groupPolicy** — Must be `"open"` or `"allowlist"` (with the group ID listed). If `"disabled"`, the bot silently ignores all group messages.

2. **requireMention** — If `true` (default), the bot only responds to @mentions and replies to its own messages. Set to `false` in `groups["*"]` to respond to all messages.

3. **Telegram Privacy Mode** (BotFather setting) — If privacy mode is enabled, the bot literally does not receive non-@mention messages from Telegram's API. This is separate from `requireMention`. Andre must change it via @BotFather → /mybots → Bot Settings → Group Privacy → Turn off.

4. **Bot was removed and re-added** — Removing and re-adding the bot to a group can reset its admin permissions and re-enable privacy mode.

## Reminder

Live config edits are emergency/convenience changes. Always remind Andre to backport changes to the `my_openclaw` repo (`openclaw-infra/config/openclaw.json` and `infra_assets/config/openclaw.json`) so the next deploy doesn't revert them.
