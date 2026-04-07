# OpenClaw Deployment Workspace

GitHub-first deployment workspace for the Contabo OpenClaw stack and the remaining compatibility assets that still live beside it.

## Root Layout

| Path | Purpose |
|------|---------|
| `openclaw-infra/` | Canonical OpenClaw stack assets: compose files, OpenClaw config and workspace files, deploy scripts |
| `infra_assets/` | Remaining shared and legacy assets for Homarr, Uptime Kuma, Infisical, Caddy, and compatibility wrappers |
| `scripts/` | Local entrypoints such as the Contabo bootstrap and deploy PowerShell scripts |
| `openclaw/` | OpenClaw app source checkout used only when a source-build deployment is required |

## Canonical Documentation

- `technical_how.md` is the current operating-model and topology document.
- `openclaw-infra/README.md` is the canonical OpenClaw infra guide.
- `infra_assets/README.md` documents the remaining compatibility assets.

## Main Deploy Commands On The VPS

```bash
# OpenClaw image-based deploy
/opt/src/openclaw/openclaw-infra/scripts/deploy-openclaw.sh

# OpenClaw source-build deploy
/opt/src/openclaw/openclaw-infra/scripts/deploy-build-openclaw.sh

# OpenClaw quick image refresh
/opt/src/openclaw/openclaw-infra/scripts/update-openclaw.sh

# Shared-service deploys that still live under infra_assets
/opt/src/openclaw/infra_assets/scripts/deploy-homarr.sh
/opt/src/openclaw/infra_assets/scripts/deploy-infisical.sh
/opt/src/openclaw/infra_assets/scripts/deploy-uptime-kuma.sh
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

## Current Runtime Notes

| Path | Purpose |
|------|---------|
| `/opt/src/openclaw` | VPS checkout of this deployment workspace |
| `/opt/openclaw` | Live OpenClaw stack directory |
| `/opt/openclaw/.env` | Runtime env vars and secrets |
| `/opt/caddy` | Standalone Contabo Caddy edge stack |
| `/root/.openclaw` | OpenClaw runtime config, workspace, sessions, credentials |

## Proper Shutdown

OpenClaw has systemd timers that poll for device approvals and manage Tailscale. To shut down the stack without it "resurrecting":

```bash
# 1. Stop and disable the timers
systemctl stop openclaw-device-approval-notifier.timer openclaw-tailscale-finalize.timer
systemctl disable openclaw-device-approval-notifier.timer openclaw-tailscale-finalize.timer

# 2. Bring down the stack
cd /opt/openclaw && docker compose down
```

## Notes

- Contabo edge routing now comes from standalone Caddy, not host nginx.
- Open WebUI deploys from the sibling `openwebui/` repo at `/opt/src/openwebui`.
- `infra_assets/scripts/apply-infra-assets.sh` remains as a compatibility wrapper for older callers.
- If you change deployment behavior or VPS topology, update `technical_how.md` in the same change.
