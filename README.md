# My OpenClaw Deployment Workspace

GitHub-first deployment workspace for the Contabo OpenClaw stack.

## Root Layout

| Path | Purpose |
|------|---------|
| `openclaw-infra/` | Canonical OpenClaw stack assets: shared Compose files, OpenClaw config/workspace, OpenClaw deploy scripts |
| `openwebui/` | Canonical Open WebUI assets: nginx templates, deploy/update scripts, service-specific docs |
| `infra_assets/` | Remaining shared and legacy assets for Homarr, Uptime Kuma, Infisical, Caddy, and compatibility wrappers |
| `scripts/` | Local entrypoints such as the Contabo bootstrap/deploy PowerShell script |
| `openclaw/` | OpenClaw app source checkout used only for source-build deployments |

## Canonical Documentation

- `technical_how.md` is the system-topology and source-of-truth document.
- `openclaw-infra/README.md` is the canonical OpenClaw infra guide.
- `openwebui/README.md` is the canonical Open WebUI guide.
- `infra_assets/README.md` documents the remaining shared and compatibility assets.

## Main Deploy Commands On The VPS

```bash
# OpenClaw image-based deploy
/opt/src/my_openclaw/openclaw-infra/scripts/deploy-openclaw.sh

# OpenClaw source-build deploy
/opt/src/my_openclaw/openclaw-infra/scripts/deploy-build-openclaw.sh

# OpenClaw quick image refresh
/opt/src/my_openclaw/openclaw-infra/scripts/update-openclaw.sh

# Open WebUI full deploy
/opt/src/my_openclaw/openwebui/scripts/deploy-openwebui.sh

# Open WebUI quick image refresh
/opt/src/my_openclaw/openwebui/scripts/update-openwebui.sh

# Shared-service deploys that still live under infra_assets
/opt/src/my_openclaw/infra_assets/scripts/deploy-homarr.sh
/opt/src/my_openclaw/infra_assets/scripts/deploy-infisical.sh
/opt/src/my_openclaw/infra_assets/scripts/deploy-uptime-kuma.sh
```

## Local Bootstrap / Redeploy

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-contabo-openclaw.ps1
powershell -ExecutionPolicy Bypass -File .\scripts\deploy-contabo-infisical.ps1
```

## Source Of Truth

- GitHub holds the intended repo-managed state.
- Local `.env` in this repo is the source of truth for OpenClaw secrets and Contabo access.
- The VPS is a deployment target, not the primary editing environment.

## Live VPS Paths

| Path | Purpose |
|------|---------|
| `/opt/src/my_openclaw` | Infra/docs/deploy repo checkout |
| `/opt/src/openclaw` | OpenClaw app source checkout for source builds |
| `/opt/openclaw` | Live Compose stack directory |
| `/opt/openclaw/.env` | Runtime env vars and secrets |
| `/opt/infisical` | Infisical data directories for Postgres and Redis |
| `/root/.openclaw` | OpenClaw runtime config, workspace, sessions, credentials |
| `/etc/nginx/sites-available/*.conf` | Public vhost definitions for Open WebUI and sibling services |

## Notes

- The shared Compose stack in `openclaw-infra/compose/docker-compose.yml` still defines OpenClaw, Open WebUI, and the sibling services that run from the Contabo host.
- `infra_assets/scripts/apply-infra-assets.sh` remains as a compatibility wrapper for older callers and for the shared Homarr/Uptime Kuma nginx assets.
- If you are changing deployment behavior, update `technical_how.md` in the same change.
