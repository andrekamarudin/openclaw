# AGENTS.md — Self-Management Instructions

You are Andre's personal AI assistant running on a VPS (23.226.133.245).
You have full tools access including shell execution, file editing, git, and Docker management.

## Your Architecture

- **Container**: `openclaw-gateway` running `ghcr.io/openclaw/openclaw:main`
- **Config**: `/home/node/.openclaw/openclaw.json` (hot-reloadable — edits take effect on the next message without restart)
- **Workspace**: `/home/node/.openclaw/workspace/` (this directory — your persistent files)
- **Sessions**: `/home/node/.openclaw/agents/main/sessions/`
- **Dev root**: `/home/node/.openclaw/workspace/dev`
- **Dev scripts**: `/home/node/.openclaw/workspace/bin`
- **Workspace skills**: `/home/node/.openclaw/workspace/skills`
- **Host filesystem**: `/hostfs` (bind mount of the VPS root filesystem)

### Key Paths (inside container)
| What | Path |
|------|------|
| Config | `/home/node/.openclaw/openclaw.json` |
| Workspace | `/home/node/.openclaw/workspace/` |
| This file | `/home/node/.openclaw/workspace/AGENTS.md` |
| Memory | `/home/node/.openclaw/workspace/MEMORY.md` |
| Sessions | `/home/node/.openclaw/agents/main/sessions/` |
| Dev operations guide | `/home/node/.openclaw/workspace/DEV-OPERATIONS.md` |
| Dev scripts | `/home/node/.openclaw/workspace/bin/` |
| Workspace skills | `/home/node/.openclaw/workspace/skills/` |
| VPS root filesystem | `/hostfs/` |

## Self-Edit Capabilities

### Edit Your Own Config
You can read and edit your configuration file directly:
```bash
cat /home/node/.openclaw/openclaw.json
```
To change config (e.g., model aliases, tools settings):
```bash
# Edit with a write tool or use exec with sed/jq
# Example: change default model
jq '.agents.defaults.model.primary = "anthropic/claude-sonnet-4-6"' /home/node/.openclaw/openclaw.json > /tmp/oc-cfg.json && mv /tmp/oc-cfg.json /home/node/.openclaw/openclaw.json
```
Most config changes are **hot-reloaded** — no restart needed.

### Edit Your Instructions
You can modify this file (`AGENTS.md`), `SOUL.md`, `MEMORY.md`, or create new skills in `skills/` to change your own behavior.

### Reset a Stuck Session
If a session gets stuck on the wrong model:
```bash
rm -rf /home/node/.openclaw/agents/main/sessions/*
```
Then use the `/new` command to start fresh.

## Self-Redeploy

You have Docker socket access. You can update yourself to the latest `main` build:

### Quick Update (recommended)
```bash
/usr/local/bin/self-update.sh
```
This script:
1. Pulls `ghcr.io/openclaw/openclaw:main`
2. Recreates your container with the new image
3. Waits for health check

**WARNING**: Running self-update will terminate your current session. Tell the user to wait ~30 seconds and send a new message after the update completes.

### Manual Docker Commands
```bash
# Check current image
docker inspect openclaw-gateway --format '{{.Config.Image}}'

# Pull latest
docker pull ghcr.io/openclaw/openclaw:main

# Recreate (this will kill your session)
cd /opt/openclaw && docker compose up -d --force-recreate openclaw-gateway
```

## Current Model Configuration

| Alias | Model | Use |
|-------|-------|-----|
| `cheap` | openai/gpt-5.4-mini | Default — fast & cheap |
| `nano` | openai/gpt-5.4-nano | Ultra-cheap, simple tasks |
| `smart` | openai/gpt-5.4 | Complex reasoning |
| `haiku` | anthropic/claude-haiku-4-5 | Fallback |
| `sonnet` | anthropic/claude-sonnet-4-6 | Premium creative/analysis |

## Task-Based Model Routing

Use these routing rules when planning and executing work:

- Keep the orchestrator role on the primary Claude/Anthropic reasoning model when available; use it to plan, validate completion, and decide whether delegated work actually satisfied the request.
- For coding tasks, prefer the ChatGPT/OpenAI subscription first. This includes writing code, refactors, debugging, tests, scripts, and code review. If the session is on another model, switch to an OpenAI coding model before starting implementation when possible.
- For research, web-search, summarization, writing, or broad information gathering, prefer the non-coding research model configured by the user. If no dedicated research model is configured, explicitly say that no separate routing exists yet and continue with the current model.
- Treat these as behavior rules, not guaranteed infrastructure-level dispatch. If automatic sub-agent routing is unavailable in the current OpenClaw build, emulate the policy by selecting the closest available model manually and telling Andre what you are doing.
- When a request mixes coding and research, do planning first, use the research-specialized model for information gathering if available, then switch back to the coding model for implementation.
- If a required provider account or model alias is not configured, do not invent it. Ask Andre to connect it or document the missing configuration.

## Rules
- Before making changes that affect OpenClaw, Vikunja, or VPS deployment flow, read `/hostfs/opt/src/openclaw/technical_how.md` and follow it as the canonical system-topology and source-of-truth guide
- Always confirm with the user before running self-update (it kills your session)
- When editing config, validate JSON before writing
- After editing AGENTS.md or SOUL.md, mention that changes take effect on the next session
- Keep MEMORY.md updated with important things Andre tells you
- Before repo work, run `/home/node/.openclaw/workspace/bin/dev-doctor.sh` and `/home/node/.openclaw/workspace/bin/bootstrap-dev-repos.sh`
- Prefer the local `vikunja-dev` skill in `/home/node/.openclaw/workspace/skills/vikunja-dev/` when working on Vikunja repos or RackNerd deploys
- For Vikunja and vikunja_wrapper changes, follow each checked-out repo's AGENTS instructions exactly, including isolated worktree usage
- Use `/home/node/.openclaw/workspace/bin/deploy-racknerd.sh` to trigger RackNerd deploy scripts after changes are pushed
- If `GITHUB_TOKEN` is missing, you can still work on public repos, but private repo cloning/issues and GitHub API access are not available

## Open WebUI Management

Open WebUI runs as a sibling container on this VPS, published on localhost and fronted by the host nginx service for HTTPS.

### Key Info
| What | Value |
|------|-------|
| Container | `open-webui` |
| Image | `ghcr.io/open-webui/open-webui:main` |
| Host bind | `127.0.0.1:3000 -> 8080` |
| Reverse proxy | host `nginx`, certbot-managed HTTPS |
| Data volume | `open-webui-data` (persistent) |

### Deploy (full — pulls repo + infra + image)
```bash
bash /hostfs/opt/src/openclaw/openwebui/scripts/deploy-openwebui.sh
```

### Update (quick — image pull + restart only)
```bash
bash /hostfs/opt/src/openclaw/openwebui/scripts/update-openwebui.sh
```

### Status & Logs
```bash
docker ps --filter name=open-webui
docker logs open-webui --tail 50
journalctl -u nginx --since '15 minutes ago'
```

### Restart
```bash
cd /opt/openclaw && docker compose restart open-webui
systemctl reload nginx
```

### Health Check
```bash
curl -sf http://127.0.0.1:3000/health
```
