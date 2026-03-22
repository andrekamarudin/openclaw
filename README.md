# My OpenClaw Setup

Personal AI assistant running on a VPS, accessible via Telegram.

---

## Development Workflow

Same pattern as Vikunja: **local changes → push → SSH pull → deploy**.

### Repositories

| Repo | Purpose | Server path |
|------|---------|-------------|
| `my_openclaw` (this repo) | Infra assets, deploy scripts, docs | `/opt/src/my_openclaw` |
| `openclaw` (fork) | App source code (for source builds) | `/opt/src/openclaw` |

### Deploy commands (run on VPS)

```bash
# Standard deploy: pull repo + latest image + restart
/opt/src/my_openclaw/infra_assets/scripts/deploy-openclaw.sh

# Quick image update only (no repo pull)
/opt/src/my_openclaw/infra_assets/scripts/update-openclaw.sh

# Source build deploy (when you have app code changes in your fork)
/opt/src/my_openclaw/infra_assets/scripts/deploy-build-openclaw.sh
```

### Deploy from local PowerShell

```powershell
# Infra-only deploy (docker-compose, script changes)
ssh vikunja-prod "/opt/src/my_openclaw/infra_assets/scripts/deploy-openclaw.sh"

# Source build deploy (app code changes)
ssh vikunja-prod "/opt/src/my_openclaw/infra_assets/scripts/deploy-build-openclaw.sh"
```

### First-time server setup

```bash
# Clone this repo
git clone https://github.com/andrekamarudin/my_openclaw.git /opt/src/my_openclaw

# Clone your openclaw fork (only needed for source builds)
git clone https://github.com/andrekamarudin/openclaw.git /opt/src/openclaw

# Apply infra assets (copies docker-compose.yml to /opt/openclaw/)
/opt/src/my_openclaw/infra_assets/scripts/apply-infra-assets.sh

# Make sure .env exists at /opt/openclaw/.env with your API keys
# Then start:
cd /opt/openclaw && docker compose up -d
```

---

## Architecture

```
Telegram (@drekian_oc_bot)
        │
        ▼
┌─────────────────────────────┐
│   VPS (23.226.133.245)      │
│   Ubuntu 24.04 · 2GB RAM    │
│                             │
│   Docker Container          │
│   openclaw-gateway          │
│   Port 18789 (gateway)      │
│   Port 18790 (bridge)       │
│                             │
│   Also runs: Vikunja        │
└─────────────────────────────┘
```

---

## Server Details

| Item | Value |
|------|-------|
| VPS IP | `23.226.133.245` |
| SSH alias | `vikunja-prod` |
| SSH user | `root` |
| SSH key | `~/.ssh/id_ed25519` |
| OS | Ubuntu 24.04.4 LTS |
| RAM | 2 GB + 1 GB swap |
| Docker | v29.3 + Compose v5.1 |
| OpenClaw version | 2026.3.13 |
| Image | `ghcr.io/openclaw/openclaw:latest` |
| Restart policy | `unless-stopped` |

---

## Telegram Bot

| Item | Value |
|------|-------|
| Bot username | `@drekian_oc_bot` |
| Your Telegram ID | `876499264` |
| DM policy | `allowlist` (only you) |
| Group policy | `disabled` |

---

## File Locations (on VPS)

| File | Purpose |
|------|---------|
| `/opt/openclaw/docker-compose.yml` | Docker Compose stack definition |
| `/opt/openclaw/.env` | API keys and env vars for Docker |
| `/root/.openclaw/openclaw.json` | OpenClaw runtime config (models, channels, gateway) |
| `/root/.openclaw/agents/main/sessions/` | Persisted chat sessions |
| `/root/.openclaw/workspace/` | Agent workspace (AGENTS.md, SOUL.md, etc.) |
| `/root/.openclaw/credentials/` | Telegram pairing data |

---

## API Keys

All stored in `/opt/openclaw/.env` on the VPS. The container reads them as
environment variables.

| Variable | Provider | Used For |
|----------|----------|----------|
| `ANTHROPIC_API_KEY` | Anthropic | Claude models |
| `OPENAI_API_KEY` | OpenAI | GPT models, image gen, whisper |
| `OPENROUTER_API_KEY` | OpenRouter | Multi-provider routing |
| `GROQ_API_KEY` | Groq | Fast inference |
| `PERPLEXITY_API_KEY` | Perplexity | Search-augmented answers |
| `TELEGRAM_BOT_TOKEN` | Telegram BotFather | Bot connection |
| `ELEVENLABS_API_KEY` | ElevenLabs | Text-to-speech |
| `DEEPGRAM_API_KEY` | Deepgram | Speech-to-text |
| `TAVILY_API_KEY` | Tavily | Web search |
| `SERPER_API_KEY` | Serper | Google search |

To update a key: `ssh vikunja-prod "nano /opt/openclaw/.env"` then recreate the
container with `ssh vikunja-prod "cd /opt/openclaw && docker compose up -d"`.

---

## Model Configuration

Default model: `anthropic/claude-haiku-4-5` (cheap, safe default on this OpenClaw build)

### Available Models (configured aliases)

| Alias | Model | Provider | Input Cost | Output Cost |
|-------|-------|----------|-----------|-------------|
| `cheap` | `claude-haiku-4-5` | Anthropic | $1.00/MTok | $5.00/MTok |
| `smart` | `gpt-5.4` | OpenAI | $2.50/MTok | $15.00/MTok |
| `sonnet` | `claude-sonnet-4.6` | Anthropic | $3.00/MTok | $15.00/MTok |

### Switching Models

**Temporary (current session only):** Type `/model smart` in Telegram.
Resets to default on `/new`.

**Permanent (change default):** Edit `agents.defaults.model.primary` in
`/root/.openclaw/openclaw.json`, then restart the gateway.

### Cost Guidance

For casual daily use with `claude-haiku-4-5`, expect materially lower cost than
Sonnet or Opus. Switching to `smart` or `sonnet` for specific tasks is fine —
just switch back with `/model cheap` or `/new` when done.

---

## Current Config (openclaw.json)

```json
{
  "agents": {
    "defaults": {
      "model": {
        "primary": "anthropic/claude-haiku-4-5",
        "fallbacks": ["openai/gpt-5.4"]
      },
      "models": {
        "anthropic/claude-haiku-4-5": { "alias": "cheap" },
        "openai/gpt-5.4": { "alias": "smart" },
        "anthropic/claude-sonnet-4-6": { "alias": "sonnet" }
      }
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "dmPolicy": "allowlist",
      "botToken": "<your-bot-token>",
      "groupPolicy": "disabled",
      "streaming": "partial",
      "allowFrom": [876499264]
    }
  },
  "gateway": {
    "mode": "local",
    "bind": "lan",
    "controlUi": {
      "allowedOrigins": [
        "http://localhost:18789",
        "http://127.0.0.1:18789",
        "http://23.226.133.245:18789"
      ]
    },
    "auth": { "mode": "token" }
  }
}
```

---

## Important Gotchas

### Session model pinning
When you switch models with `/model`, the session remembers that model even
across container restarts. Use `/new` to reset and pick up the configured
default again.

### OpenAI mini/nano naming trap
This OpenClaw build rejected `openai/gpt-5.4-mini` with `Unknown model` even
though the OpenAI account itself exposes that model. Do not use the versioned
mini/nano refs in this setup unless you re-test them after an OpenClaw update.
Use the current safe aliases instead: `cheap`, `smart`, `sonnet`.

### File permissions
The container runs as uid `1000` (node user). After editing any file under
`/root/.openclaw/` from the host, always run:
```bash
chown -R 1000:1000 /root/.openclaw
```

### Config hot reload
Most config changes (models, channels, agents) hot-reload automatically. Gateway
settings (port, bind, auth) require a restart.

### Memory pressure
The VPS has 2GB RAM. OpenClaw uses ~1GB at runtime. Vikunja uses the rest. If
the server becomes unresponsive, reboot from your VPS provider panel, then
start OpenClaw again.

### Docker restart policy
The container has `restart: unless-stopped`. It auto-starts on server boot as
long as Docker is enabled. If you manually `docker compose down`, it won't
restart until you `docker compose up -d` again.

### Env file vs config file
- `/opt/openclaw/.env` → API keys, gateway token, timezone. Changes require
  container recreation (`docker compose up -d`).
- `/root/.openclaw/openclaw.json` → Models, channels, gateway behavior. Most
  changes hot-reload; restart for gateway settings.

### Updating OpenClaw
```bash
# From local PowerShell:
ssh vikunja-prod "/opt/src/my_openclaw/infra_assets/scripts/update-openclaw.sh"

# Or directly on VPS:
/opt/src/my_openclaw/infra_assets/scripts/update-openclaw.sh
```
The `doctor` migration runs on startup and may rewrite parts of your config to
match the latest schema. This is normal.

---

## Links

- [OpenClaw GitHub](https://github.com/openclaw/openclaw)
- [OpenClaw Docs](https://docs.openclaw.ai/)
- [Configuration Reference](https://docs.openclaw.ai/gateway/configuration)
- [Models Reference](https://docs.openclaw.ai/concepts/models)
- [Telegram Channel Docs](https://docs.openclaw.ai/channels/telegram)
- [Docker Install Docs](https://docs.openclaw.ai/install/docker)
