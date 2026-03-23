#!/usr/bin/env bash
set -euo pipefail

# Deploy Open WebUI: pull repo, apply infra assets, pull latest image, start services.

OC_ROOT_DIR="${OC_ROOT_DIR:-/opt/openclaw}"
OC_REPO_DIR="${OC_REPO_DIR:-/opt/src/my_openclaw}"

cd "$OC_REPO_DIR"
git pull --ff-only origin master

bash "$OC_REPO_DIR/infra_assets/scripts/apply-infra-assets.sh"

cd "$OC_ROOT_DIR"
docker compose pull open-webui
docker compose up -d --no-deps open-webui

bash "$OC_REPO_DIR/infra_assets/scripts/enable-openwebui-nginx.sh"

echo "Open WebUI deploy complete"
