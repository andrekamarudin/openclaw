## infra_assets

Version-controlled source of truth for OpenClaw production infrastructure files.

Keep here:

- Docker Compose stack definition
- Deploy helper scripts
- OpenClaw config template (without secrets)
- Agent workspace files (AGENTS.md, MEMORY.md)
- Other small declarative server assets that should be reviewed in Git

Do not keep here:

- Secrets or API keys
- Private SSH keys
- Live `.env` files
- Runtime-generated files

Current production targets:

- `compose/docker-compose.yml` -> `/opt/openclaw/docker-compose.yml`
- `compose/docker-compose.build.yml` -> `/opt/openclaw/docker-compose.build.yml`
- `nginx/openwebui-http.conf` -> `/etc/nginx/sites-available/<domain>.conf` (bootstrap HTTP config)
- `nginx/openwebui-https.conf` -> `/etc/nginx/sites-available/<domain>.conf` (HTTPS config after cert issuance)
- `scripts/self-update.sh` -> `/opt/openclaw/self-update.sh`
- `config/openclaw.json.template` -> `/root/.openclaw/openclaw.json` (seed only, won't overwrite)
- `workspace/AGENTS.md` -> `/root/.openclaw/workspace/AGENTS.md` (always synced)
- `workspace/MEMORY.md` -> `/root/.openclaw/workspace/MEMORY.md` (seed only, won't overwrite)

Repo-managed operational scripts are executed in place from:

- `scripts/*.sh` -> `/opt/src/my_openclaw/infra_assets/scripts/*.sh`

Sync these files onto the VPS with:

```bash
/opt/src/my_openclaw/infra_assets/scripts/apply-infra-assets.sh
```
