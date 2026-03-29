#!/usr/bin/env bash
set -euo pipefail

# Deploy OpenClaw: pull repo, apply infra assets, pull latest image, restart.
# This is the image-based deploy (no source build).

OC_ROOT_DIR="${OC_ROOT_DIR:-/opt/openclaw}"
OC_REPO_DIR="${OC_REPO_DIR:-/opt/src/openclaw}"

cd "$OC_REPO_DIR"
git checkout -- .
git pull --ff-only origin master

bash "$OC_REPO_DIR/openclaw-infra/scripts/apply-openclaw-infra.sh"

# Fetch secrets from Infisical
INFISICAL_ENV="/opt/src/self_hosting/infra/scripts/infisical-env.sh"
if [ -f "$INFISICAL_ENV" ]; then
    # shellcheck disable=SC1090
    source "$INFISICAL_ENV"
    infisical_fetch contabo-openclaw "$OC_ROOT_DIR/.env" prod || true
fi

cd "$OC_ROOT_DIR"
docker compose pull openclaw-gateway
docker compose up -d --no-deps openclaw-gateway

# Fix permissions for the openclaw config dir
chown -R 1000:1000 /root/.openclaw

echo "OpenClaw deploy complete"
