#!/usr/bin/env bash
set -euo pipefail

# Pull the latest Open WebUI image and restart.
# Quick update without touching infra assets or repo.

OC_ROOT_DIR="${OC_ROOT_DIR:-/opt/openclaw}"

cd "$OC_ROOT_DIR"
docker compose pull open-webui
docker compose up -d --no-deps open-webui
bash "${OC_REPO_DIR:-/opt/src/my_openclaw}/infra_assets/scripts/enable-openwebui-nginx.sh"

echo "Open WebUI image update complete"
