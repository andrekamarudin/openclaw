# My OpenClaw Setup

Personal AI assistant running on a VPS, accessible via Telegram.

---

## Source Of Truth

- GitHub is the source of truth for app code, infra assets, config templates, and deploy scripts.
- Local `.env` in this repo is the source of truth for OpenClaw secrets and Contabo host access.
- The VPS only receives copies during deployment.

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

# Deploy Open WebUI: pull repo + latest image + ensure Caddy running
/opt/src/my_openclaw/infra_assets/scripts/deploy-openwebui.sh

# Quick Open WebUI image update only
/opt/src/my_openclaw/infra_assets/scripts/update-openwebui.sh
```

### Deploy from local PowerShell

```powershell
# Push local .env, pull from GitHub, and redeploy on Contabo
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-contabo-openclaw.ps1
```

### First-time server setup

```bash
# Clone this repo
git clone https://github.com/andrekamarudin/my_openclaw.git /opt/src/my_openclaw

# Clone your openclaw fork (only needed for source builds)
git clone https://github.com/andrekamarudin/openclaw.git /opt/src/openclaw

# Apply infra assets (copies docker-compose.yml to /opt/openclaw/)
/opt/src/my_openclaw/infra_assets/scripts/apply-infra-assets.sh

# Push local .env and let the deploy script bootstrap the server:
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-contabo-openclaw.ps1
```

---

## Architecture

```
Telegram (@drekian_oc_bot)
        │
        ▼
┌──────────────────────────────────┐
│   Contabo VPS (46.250.234.28)   │
│   Ubuntu 24.04 · 12GB RAM       │
│                                  │
│   openclaw-gateway  :18789/18790 │
│   openclaw-cli                   │
│   open-webui        :8080 (int)  │
│   caddy             :80/443      │
│                                  │
│   Caddy -> open-webui (HTTPS)    │
└──────────────────────────────────┘
```

---

## Server Details

| Item | Value |
|------|-------|
| VPS IP | `46.250.234.28` |
| VPS provider | Contabo |
| SSH user | `root` |
| SSH key | `~/.ssh/id_ed25519` |
| OS | Ubuntu 24.04 LTS |
| RAM | 12 GB |
| Docker | v29.3 + Compose v5.1 |
| OpenClaw channel | `main` (tracks latest unreleased features) |
| OpenClaw image | `ghcr.io/openclaw/openclaw:main` |
| Open WebUI image | `ghcr.io/open-webui/open-webui:main` |
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
| `/opt/openclaw/Caddyfile` | Caddy reverse proxy config (synced from repo) |
| `/opt/openclaw/self-update.sh` | Agent self-redeploy script (mounted into container) |
| `/root/.openclaw/openclaw.json` | OpenClaw runtime config (models, channels, gateway) |
| `/root/.openclaw/agents/main/sessions/` | Persisted chat sessions |
| `/root/.openclaw/workspace/` | Agent workspace (AGENTS.md, MEMORY.md, etc.) |
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

Default model: `openai/gpt-5.4-mini` (cheap, fast)

### Available Models (configured aliases)

| Alias | Model | Provider | Input Cost | Output Cost |
|-------|-------|----------|-----------|-------------|
| `cheap` | `gpt-5.4-mini` | OpenAI | $0.40/MTok | $1.60/MTok |
| `nano` | `gpt-5.4-nano` | OpenAI | $0.10/MTok | $0.40/MTok |
| `smart` | `gpt-5.4` | OpenAI | $2.50/MTok | $15.00/MTok |
| `haiku` | `claude-haiku-4-5` | Anthropic | $1.00/MTok | $5.00/MTok |
| `sonnet` | `claude-sonnet-4-6` | Anthropic | $3.00/MTok | $15.00/MTok |

### Switching Models

**Temporary (current session only):** Type `/model smart` in Telegram.
Resets to default on `/new`.

**Permanent (change default):** Edit `agents.defaults.model.primary` in
`/root/.openclaw/openclaw.json`, then restart the gateway.

### Cost Guidance

For casual daily use with `gpt-5.4-mini`, expect very low cost.
Switching to `smart` or `sonnet` for specific tasks is fine —
just switch back with `/model cheap` or `/new` when done.

---

## Current Config

The config template lives at `infra_assets/config/openclaw.json.template`.
It is seeded to `/root/.openclaw/openclaw.json` on first deploy.
See the template file for the full current config.

Key settings:
- Default model: `openai/gpt-5.4-mini` with `anthropic/claude-haiku-4-5` fallback
- Tools profile: `full` (shell, file I/O, Docker access)
- Elevated execution: enabled for Telegram user `876499264`
- Telegram: allowlist-only DMs, streaming partial

---

## Important Gotchas

### Session model pinning
When you switch models with `/model`, the session remembers that model even
across container restarts. Use `/new` to reset and pick up the configured
default again.

### Self-management
The agent has Docker socket access and can pull/redeploy itself via
`/usr/local/bin/self-update.sh` (mounted into the container). The AGENTS.md
workspace file teaches it how. Always ask the agent to confirm before self-update.

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

# Or ask the bot itself in Telegram:
# "update yourself to the latest version"
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
