# OpenClaw Infra

Canonical OpenClaw deployment assets for the Contabo stack.

## What Lives Here

- Shared compose files for the live `/opt/openclaw` stack
- OpenClaw runtime config template
- Synced OpenClaw workspace files such as `AGENTS.md`, memory files, tools, and skills
- OpenClaw-specific deploy and update scripts
- The self-update script mounted into the gateway container

## What Does Not Live Here

- secrets or API keys
- live `.env` files
- runtime-generated sessions, credentials, or workspace data
- shared edge Caddy config for sibling services managed elsewhere in the workspace

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
| `scripts/apply-openclaw-infra.sh` | Sync OpenClaw assets to the VPS |
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

- The compose files in this folder remain the source of truth for `/opt/openclaw`.
- Standalone Contabo Caddy is managed outside this directory.
- Open WebUI now deploys from the sibling `openwebui/` repo.
- The older `infra_assets/scripts/*.sh` OpenClaw paths still exist only as compatibility wrappers.

## First-Time Setup

```bash
git clone https://github.com/andrekamarudin/openclaw-infra.git /opt/src/openclaw
/opt/src/openclaw/openclaw-infra/scripts/apply-openclaw-infra.sh
```

If you plan to run source builds, make sure the checkout contains the OpenClaw source expected by the compose build inputs before invoking `deploy-build-openclaw.sh`.