#!/usr/bin/env bash
set -euo pipefail

# Deploy Uptime Kuma: pull repo, apply infra assets, pull latest image, start service, enable nginx.

OC_ROOT_DIR="${OC_ROOT_DIR:-/opt/openclaw}"
OC_REPO_DIR="${OC_REPO_DIR:-/opt/src/openclaw}"

cd "$OC_REPO_DIR"
git pull --ff-only origin master

bash "$OC_REPO_DIR/infra_assets/scripts/apply-infra-assets.sh"

mkdir -p /opt/uptime-kuma

cd "$OC_ROOT_DIR"
docker compose pull uptime-kuma
docker compose up -d --no-deps uptime-kuma

bash "$OC_REPO_DIR/infra_assets/scripts/enable-uptime-kuma-nginx.sh"

echo "Uptime Kuma deploy complete"
