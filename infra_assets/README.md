# Shared Infra Assets

This directory is no longer the canonical home for OpenClaw or Open WebUI assets.

## What Still Lives Here

- Homarr nginx templates and deploy helpers
- Uptime Kuma nginx templates and deploy helpers
- Infisical nginx templates and deploy helpers
- Caddy-related files that are still referenced by other planning/docs work
- Compatibility wrappers that preserve the older `infra_assets/scripts/...` entrypoints

## Canonical Locations Now

- OpenClaw infra: `../openclaw-infra/`
- Open WebUI assets: `../openwebui/`

## Shared/Legacy Scripts

| Script | Role |
|--------|------|
| `scripts/apply-infra-assets.sh` | Compatibility wrapper that calls `openclaw-infra/scripts/apply-openclaw-infra.sh` and then applies the remaining shared nginx assets |
| `scripts/deploy-homarr.sh` | Homarr deploy helper |
| `scripts/deploy-infisical.sh` | Infisical deploy helper |
| `scripts/deploy-uptime-kuma.sh` | Uptime Kuma deploy helper |
| `scripts/enable-homarr-nginx.sh` | Homarr cert/nginx helper |
| `scripts/enable-infisical-nginx.sh` | Infisical cert/nginx helper |
| `scripts/enable-uptime-kuma-nginx.sh` | Uptime Kuma cert/nginx helper |

## VPS Paths Still Managed From Here

- `nginx/homarr-*.conf` -> `/etc/nginx/sites-available/<homarr-domain>.conf`
- `nginx/infisical-*.conf` -> `/etc/nginx/sites-available/<infisical-domain>.conf`
- `nginx/uptime-kuma-*.conf` -> `/etc/nginx/sites-available/<uptime-kuma-domain>.conf`
- `scripts/*.sh` -> `/opt/src/my_openclaw/infra_assets/scripts/*.sh`

## Compatibility Entry Point

```bash
/opt/src/my_openclaw/infra_assets/scripts/apply-infra-assets.sh
```

Use that only when you need the shared legacy behavior. For OpenClaw and Open WebUI work, use the new canonical folders directly.
