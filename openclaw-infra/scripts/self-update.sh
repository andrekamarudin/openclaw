#!/usr/bin/env bash
set -euo pipefail

# Self-update script for OpenClaw.
# Mounted into the container at /usr/local/bin/self-update.sh so the agent
# can pull and redeploy itself via Docker socket.

OPENCLAW_IMAGE="${OPENCLAW_IMAGE:-ghcr.io/openclaw/openclaw:latest}"

echo "==> Pulling ${OPENCLAW_IMAGE}..."
docker pull "$OPENCLAW_IMAGE"

echo '==> Recreating containers with new image...'
cd /opt/openclaw
docker compose up -d --force-recreate openclaw-gateway

echo '==> Waiting for health check...'
for i in {1..30}; do
  if curl -sf http://127.0.0.1:18789/healthz > /dev/null 2>&1; then
    echo '==> Gateway is healthy!'
    exit 0
  fi
  sleep 2
done

echo '==> WARNING: Gateway did not become healthy within 60s'
exit 1
