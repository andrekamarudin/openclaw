#!/usr/bin/env bash
set -euo pipefail

# Deploy OpenClaw from source: pull both repos, build image, restart.
# Use this when you have local app code changes in your openclaw fork.
# WARNING: Building OpenClaw from source requires significant RAM (~4GB+).

OC_ROOT_DIR="${OC_ROOT_DIR:-/opt/openclaw}"
OC_REPO_DIR="${OC_REPO_DIR:-/opt/src/my_openclaw}"
OC_SRC_DIR="${OC_SRC_DIR:-/opt/src/openclaw}"

cd "$OC_REPO_DIR"
git pull --ff-only origin master

cd "$OC_SRC_DIR"
git pull --ff-only origin main

bash "$OC_REPO_DIR/infra_assets/scripts/apply-infra-assets.sh"

cd "$OC_ROOT_DIR"
docker compose -f docker-compose.yml -f docker-compose.build.yml up -d --no-deps --build openclaw-gateway

# Fix permissions for the openclaw config dir
chown -R 1000:1000 /root/.openclaw

echo "OpenClaw source build deploy complete"
