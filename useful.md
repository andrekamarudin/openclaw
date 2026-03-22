# OpenClaw Useful Commands

All commands run from your local PowerShell unless noted otherwise.

SSH alias: `vikunja-prod` → `root@23.226.133.245`

---

## Telegram Chat Commands (type these in Telegram)

```
/new              Reset session (clears context + model pin, starts fresh)
/reset            Same as /new
/status           Show current model, tokens, cache, session info
/compact          Compress session context (keeps summary, frees tokens)
/model            List available models (numbered picker)
/model list       Same as /model
/model <number>   Pick a model by number from the picker
/model cheap      Switch to gpt-5.4-mini (default)
/model nano       Switch to gpt-5.4-nano (ultra-cheap)
/model smart      Switch to gpt-5.4 (smarter, costs more)
/model haiku      Switch to claude-haiku-4-5
/model sonnet     Switch to claude-sonnet-4-6
/help             Show all available commands
/commands         Full command list
/think <level>    Set thinking level: off|minimal|low|medium|high|xhigh
/verbose on|off   Toggle verbose output
/usage off|tokens|full   Per-response usage footer
/whoami           Show your identity info
/context          Show context breakdown
```

**Key insight:** `/new` is how you reset the session yourself. This clears the
model pin, context, and starts fresh with the configured default model.

---

## Server Management (from PowerShell)

### Check health
```powershell
ssh vikunja-prod "curl -s http://127.0.0.1:18789/healthz; echo; curl -s http://127.0.0.1:18789/readyz"
```

### View logs (last 50 lines)
```powershell
ssh vikunja-prod "docker logs openclaw-gateway --tail 50 2>&1"
```

### View logs filtered for errors
```powershell
ssh vikunja-prod "docker logs openclaw-gateway 2>&1 | grep -iE 'error|401|fail|crash' | tail -30"
```

### Restart OpenClaw
```powershell
ssh vikunja-prod "cd /opt/openclaw && docker compose restart openclaw-gateway"
```

### Full restart (recreate container)
```powershell
ssh vikunja-prod "chown -R 1000:1000 /root/.openclaw && cd /opt/openclaw && docker compose up -d"
```

### Stop OpenClaw
```powershell
ssh vikunja-prod "cd /opt/openclaw && docker compose down"
```

### Start OpenClaw
```powershell
ssh vikunja-prod "chown -R 1000:1000 /root/.openclaw && cd /opt/openclaw && docker compose up -d"
```

### Check container status
```powershell
ssh vikunja-prod "docker ps --filter name=openclaw"
```

### Check server memory
```powershell
ssh vikunja-prod "free -m"
```

---

## Config Editing

### Edit the main config
```powershell
ssh vikunja-prod "nano /root/.openclaw/openclaw.json"
```
After saving, fix permissions and restart:
```powershell
ssh vikunja-prod "chown -R 1000:1000 /root/.openclaw && cd /opt/openclaw && docker compose restart openclaw-gateway"
```

### Edit API keys
```powershell
ssh vikunja-prod "nano /opt/openclaw/.env"
```
After saving, recreate container to pick up env changes:
```powershell
ssh vikunja-prod "cd /opt/openclaw && docker compose up -d"
```

---

## Model Management

### Change default model (persistent)
Edit config → change `agents.defaults.model.primary`:
```powershell
ssh vikunja-prod "nano /root/.openclaw/openclaw.json"
```
Then restart:
```powershell
ssh vikunja-prod "chown -R 1000:1000 /root/.openclaw && cd /opt/openclaw && docker compose restart openclaw-gateway"
```

### Switch model for current session only (Telegram)
```
/model smart
```
This only lasts until you `/new` or `/reset`.

---

## Session Management

### Nuclear reset (clear all sessions from server)
```powershell
ssh vikunja-prod "rm -f /root/.openclaw/agents/main/sessions/*.jsonl && python3 -c 'import json; from pathlib import Path; p=Path(\"/root/.openclaw/agents/main/sessions/sessions.json\"); p.write_text(\"{}\n\")' && chown -R 1000:1000 /root/.openclaw && cd /opt/openclaw && docker compose restart openclaw-gateway"
```

---

## Update OpenClaw

### Pull latest image and restart
```powershell
ssh vikunja-prod "/opt/src/my_openclaw/infra_assets/scripts/update-openclaw.sh"
```

### Full deploy (pull repo + apply infra + restart)
```powershell
ssh vikunja-prod "/opt/src/my_openclaw/infra_assets/scripts/deploy-openclaw.sh"
```

### Ask the bot to update itself (from Telegram)
```
Update yourself to the latest version
```
It will run `self-update.sh` — expect ~30s downtime.

---

## Troubleshooting

### Bot not responding?
1. Check container: `ssh vikunja-prod "docker ps --filter name=openclaw-gateway"`
2. If exited: `ssh vikunja-prod "chown -R 1000:1000 /root/.openclaw && cd /opt/openclaw && docker compose up -d"`
3. Check health: `ssh vikunja-prod "curl -s http://127.0.0.1:18789/healthz"`

### Bot using wrong model?
1. In Telegram: `/new` (resets session to default model)
2. Then `/status` to confirm

### Unknown model error?
1. In Telegram: `/new`
2. Then: `/model list`
3. Pick one of the listed models instead of typing an old cached ref
4. Current safe choices are: `/model cheap`, `/model nano`, `/model smart`, `/model haiku`, `/model sonnet`

### 401 authentication errors?
Your API key is wrong or expired. Edit `/opt/openclaw/.env` and update the key.

### Server out of memory?
The VPS has 2GB RAM. OpenClaw uses ~1GB. If it's unresponsive:
1. Reboot VPS from provider UI
2. Then: `ssh vikunja-prod "chown -R 1000:1000 /root/.openclaw && cd /opt/openclaw && docker compose up -d"`
