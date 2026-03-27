# OpenClaw Infra

Canonical OpenClaw deployment assets for the Contabo stack.

## What Lives Here

- Shared Compose files for the live `/opt/openclaw` stack
- OpenClaw runtime config template
- The synced OpenClaw workspace files (`AGENTS.md`, `MEMORY.md`, tools, skills)
- OpenClaw-specific deploy/update scripts
- The self-update script mounted into the gateway container

## What Does Not Live Here

- Secrets or API keys
- Live `.env` files
- Runtime-generated sessions, credentials, or workspace data
- Open WebUI nginx templates and WebUI-specific deploy scripts

## VPS Targets

| Repo path | VPS target |
|-----------|------------|
| `compose/docker-compose.yml` | `/opt/openclaw/docker-compose.yml` |
| `compose/docker-compose.build.yml` | `/opt/openclaw/docker-compose.build.yml` |
| `config/openclaw.json` | `/root/.openclaw/openclaw.json` |
| `workspace/*` | `/root/.openclaw/workspace/*` |
| `scripts/self-update.sh` | `/opt/openclaw/self-update.sh` |

## Canonical Scripts

| Script | Purpose |
|--------|---------|
| `scripts/apply-openclaw-infra.sh` | Sync OpenClaw assets plus the Open WebUI nginx templates to the VPS |
| `scripts/deploy-openclaw.sh` | Pull repo changes, sync assets, pull the latest image, restart OpenClaw |
| `scripts/deploy-build-openclaw.sh` | Pull repo changes, sync assets, build OpenClaw from source, restart it |
| `scripts/update-openclaw.sh` | Quick image refresh without a repo pull |
| `scripts/self-update.sh` | In-container self-update helper mounted at `/usr/local/bin/self-update.sh` |

## Canonical VPS Commands

```bash
/opt/src/openclaw/openclaw-infra/scripts/apply-openclaw-infra.sh
/opt/src/openclaw/openclaw-infra/scripts/deploy-openclaw.sh
/opt/src/openclaw/openclaw-infra/scripts/deploy-build-openclaw.sh
/opt/src/openclaw/openclaw-infra/scripts/update-openclaw.sh
```

## Notes

- The shared Compose file in this folder remains the source of truth for the full `/opt/openclaw` stack, including Open WebUI and the sibling services that run alongside OpenClaw.
- Open WebUI-specific nginx templates and deploy scripts live under `../openwebui/`.
- The older `infra_assets/scripts/*.sh` OpenClaw paths now exist only as compatibility wrappers.

## First-Time Setup

```bash
git clone https://github.com/andrekamarudin/openclaw.git /opt/src/openclaw
git clone https://github.com/andrekamarudin/openclaw.git /opt/src/openclaw
/opt/src/openclaw/openclaw-infra/scripts/apply-openclaw-infra.sh
```