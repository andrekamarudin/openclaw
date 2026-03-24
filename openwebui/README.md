# Open WebUI

Canonical Open WebUI-specific deployment assets for the Contabo stack.

## What Lives Here

- nginx templates for the Open WebUI vhost
- Open WebUI deploy/update scripts
- Open WebUI-specific documentation

## Relationship To The Shared Compose Stack

Open WebUI still runs inside the shared `/opt/openclaw` Compose stack. Its service definition remains in `../openclaw-infra/compose/docker-compose.yml` because Open WebUI is deployed alongside OpenClaw and the sibling services on the same VPS.

## VPS Targets

| Repo path | VPS target |
|-----------|------------|
| `nginx/openwebui-http.conf` | `/etc/nginx/sites-available/<domain>.conf` before a certificate exists |
| `nginx/openwebui-https.conf` | `/etc/nginx/sites-available/<domain>.conf` after certificate issuance |
| `scripts/*.sh` | `/opt/src/my_openclaw/openwebui/scripts/*.sh` |

## Canonical Scripts

| Script | Purpose |
|--------|---------|
| `scripts/deploy-openwebui.sh` | Pull repo changes, sync assets, pull the latest Open WebUI image, restart the service |
| `scripts/update-openwebui.sh` | Quick image refresh without a repo pull |
| `scripts/enable-openwebui-nginx.sh` | Ensure certbot/nginx are configured, then re-apply the rendered vhost config |

## Canonical VPS Commands

```bash
/opt/src/my_openclaw/openwebui/scripts/deploy-openwebui.sh
/opt/src/my_openclaw/openwebui/scripts/update-openwebui.sh
/opt/src/my_openclaw/openwebui/scripts/enable-openwebui-nginx.sh
```

## Live Paths And Checks

| Path or command | Purpose |
|-----------------|---------|
| `/opt/openclaw/docker-compose.yml` | Shared live stack definition |
| `/opt/openclaw/.env` | Runtime env vars, including `OPENWEBUI_DOMAIN` and `OPENWEBUI_BIND_PORT` |
| `/etc/nginx/sites-available/<domain>.conf` | Rendered nginx site file |
| `curl -sf http://127.0.0.1:3000/health` | Basic local health check |
| `docker logs open-webui --tail 50` | Quick log inspection |

## Notes

- `openclaw-infra/scripts/apply-openclaw-infra.sh` renders the Open WebUI nginx templates from this folder.
- The older `infra_assets/scripts/deploy-openwebui.sh`, `update-openwebui.sh`, and `enable-openwebui-nginx.sh` files are compatibility wrappers only.
- Public signup stays disabled; admin-managed accounts are the intended operating model.