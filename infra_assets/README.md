## infra_assets

Version-controlled source of truth for OpenClaw production infrastructure files.

Keep here:

- Docker Compose stack definition
- Deploy helper scripts
- Other small declarative server assets that should be reviewed in Git

Do not keep here:

- Secrets or API keys
- Private SSH keys
- Live `.env` files
- Runtime-generated files

Current production targets:

- `compose/docker-compose.yml` -> `/opt/openclaw/docker-compose.yml`

Repo-managed operational scripts are executed in place from:

- `scripts/*.sh` -> `/opt/src/my_openclaw/infra_assets/scripts/*.sh`

Sync these files onto the VPS with:

```bash
/opt/src/my_openclaw/infra_assets/scripts/apply-infra-assets.sh
```
