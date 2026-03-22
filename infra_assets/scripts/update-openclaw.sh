#!/usr/bin/env bash
set -euo pipefail

# Pull the latest OpenClaw image and restart.
# Quick update without touching infra assets or repo.

OC_ROOT_DIR="${OC_ROOT_DIR:-/opt/openclaw}"

cd "$OC_ROOT_DIR"
docker compose pull openclaw-gateway
docker compose up -d --no-deps openclaw-gateway

chown -R 1000:1000 /root/.openclaw

echo "OpenClaw image update complete"
