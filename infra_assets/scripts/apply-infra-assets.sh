#!/usr/bin/env bash
set -euo pipefail

# Sync repo-managed infra files to /opt/openclaw on the VPS.
# Run this from the VPS after pulling the latest my_openclaw repo.

OC_ROOT_DIR="${OC_ROOT_DIR:-/opt/openclaw}"
OC_REPO_DIR="${OC_REPO_DIR:-/opt/src/my_openclaw}"
SCRIPT_DIR="$OC_REPO_DIR/infra_assets/scripts"

SOURCE_COMPOSE_FILE="$OC_REPO_DIR/infra_assets/compose/docker-compose.yml"
TARGET_COMPOSE_FILE="$OC_ROOT_DIR/docker-compose.yml"

SCRIPT_NAMES=(
    apply-infra-assets.sh
    deploy-openclaw.sh
    deploy-build-openclaw.sh
    update-openclaw.sh
)

if [ ! -f "$SOURCE_COMPOSE_FILE" ]; then
    echo "Missing source compose file: $SOURCE_COMPOSE_FILE" >&2
    exit 1
fi

mkdir -p "$OC_ROOT_DIR"

cp "$SOURCE_COMPOSE_FILE" "$TARGET_COMPOSE_FILE"

for script_name in "${SCRIPT_NAMES[@]}"; do
    source_script="$SCRIPT_DIR/$script_name"
    target_script="$OC_ROOT_DIR/$script_name"

    if [ ! -f "$source_script" ]; then
        echo "Missing source script: $source_script" >&2
        exit 1
    fi

    chmod +x "$source_script"

    # Remove stale copies from the old location
    if [ -f "$target_script" ]; then
        rm -f "$target_script"
    fi
done

echo "Applied OpenClaw infra assets from $OC_REPO_DIR to $OC_ROOT_DIR"
echo "Repo-managed scripts should be run from $SCRIPT_DIR"
