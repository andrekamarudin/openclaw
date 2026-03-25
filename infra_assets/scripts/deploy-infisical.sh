#!/usr/bin/env bash
set -euo pipefail

OC_ROOT_DIR="${OC_ROOT_DIR:-/opt/openclaw}"
OC_REPO_DIR="${OC_REPO_DIR:-/opt/src/my_openclaw}"
INFISICAL_DATA_DIR="${INFISICAL_DATA_DIR:-/opt/infisical}"

cd "$OC_REPO_DIR"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
	git pull --ff-only origin master
else
	echo "No git metadata found in $OC_REPO_DIR; deploying from uploaded snapshot"
fi

bash "$OC_REPO_DIR/infra_assets/scripts/apply-infra-assets.sh"

mkdir -p "$INFISICAL_DATA_DIR/postgres" "$INFISICAL_DATA_DIR/redis"

cd "$OC_ROOT_DIR"
docker compose pull infisical-backend infisical-db infisical-redis
docker compose up -d infisical-db infisical-redis infisical-backend

bash "$OC_REPO_DIR/infra_assets/scripts/enable-infisical-nginx.sh"

echo "Infisical deploy complete"