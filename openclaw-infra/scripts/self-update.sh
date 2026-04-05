#!/usr/bin/env bash
set -euo pipefail

# Self-update script for OpenClaw.
# Mounted into the container at /usr/local/bin/self-update.sh so the agent
# can pull and redeploy itself via Docker socket.

OPENCLAW_IMAGE="${OPENCLAW_IMAGE:-ghcr.io/openclaw/openclaw:latest}"

echo "==> Pulling ${OPENCLAW_IMAGE}..."
docker pull "$OPENCLAW_IMAGE"

echo '==> Image pulled. Not auto-starting — start manually if needed.'
echo '==> Run: cd /opt/openclaw && docker compose up -d openclaw-gateway'
