#!/usr/bin/env bash
set -euo pipefail

# Sync repo-managed infra files to /opt/openclaw and /root/.openclaw on the VPS.
# Run this from the VPS after pulling the latest my_openclaw repo.

OC_ROOT_DIR="${OC_ROOT_DIR:-/opt/openclaw}"
OC_REPO_DIR="${OC_REPO_DIR:-/opt/src/my_openclaw}"
OC_CONFIG_DIR="${OC_CONFIG_DIR:-/root/.openclaw}"
SCRIPT_DIR="$OC_REPO_DIR/infra_assets/scripts"

SOURCE_COMPOSE_FILE="$OC_REPO_DIR/infra_assets/compose/docker-compose.yml"
TARGET_COMPOSE_FILE="$OC_ROOT_DIR/docker-compose.yml"

SOURCE_BUILD_COMPOSE_FILE="$OC_REPO_DIR/infra_assets/compose/docker-compose.build.yml"
TARGET_BUILD_COMPOSE_FILE="$OC_ROOT_DIR/docker-compose.build.yml"

SCRIPT_NAMES=(
    apply-infra-assets.sh
    deploy-openclaw.sh
    deploy-build-openclaw.sh
    update-openclaw.sh
    self-update.sh
)

if [ ! -f "$SOURCE_COMPOSE_FILE" ]; then
    echo "Missing source compose file: $SOURCE_COMPOSE_FILE" >&2
    exit 1
fi

mkdir -p "$OC_ROOT_DIR"

# --- Docker Compose ---
cp "$SOURCE_COMPOSE_FILE" "$TARGET_COMPOSE_FILE"
if [ -f "$SOURCE_BUILD_COMPOSE_FILE" ]; then
    cp "$SOURCE_BUILD_COMPOSE_FILE" "$TARGET_BUILD_COMPOSE_FILE"
fi

# --- Self-update script ---
SELF_UPDATE_SRC="$SCRIPT_DIR/self-update.sh"
SELF_UPDATE_DST="$OC_ROOT_DIR/self-update.sh"
if [ -f "$SELF_UPDATE_SRC" ]; then
    cp "$SELF_UPDATE_SRC" "$SELF_UPDATE_DST"
    chmod +x "$SELF_UPDATE_DST"
fi

# --- OpenClaw config ---
# Always overwrite from repo (source of truth). Secrets are injected from .env.
OC_CONFIG_FILE="$OC_CONFIG_DIR/openclaw.json"
OC_CONFIG_SRC="$OC_REPO_DIR/infra_assets/config/openclaw.json"
if [ -f "$OC_CONFIG_SRC" ]; then
    mkdir -p "$OC_CONFIG_DIR"
    # Load secrets from .env so they can be substituted into the config
    if [ -f "$OC_ROOT_DIR/.env" ]; then
        set -a
        # shellcheck disable=SC1091
        . "$OC_ROOT_DIR/.env"
        set +a
    fi
    # Substitute ${VAR} placeholders (e.g. TELEGRAM_BOT_TOKEN) with env values
    tr -d '\r' < "$OC_CONFIG_SRC" | envsubst > "$OC_CONFIG_FILE"
    echo "Deployed openclaw.json from repo (secrets injected from .env)"
fi

# --- Workspace files ---
# Always overwrite from repo (source of truth).
WORKSPACE_DIR="$OC_CONFIG_DIR/workspace"
WORKSPACE_SRC="$OC_REPO_DIR/infra_assets/workspace"
mkdir -p "$WORKSPACE_DIR"

if [ -f "$WORKSPACE_SRC/AGENTS.md" ]; then
    cp "$WORKSPACE_SRC/AGENTS.md" "$WORKSPACE_DIR/AGENTS.md"
fi
if [ -f "$WORKSPACE_SRC/MEMORY.md" ]; then
    cp "$WORKSPACE_SRC/MEMORY.md" "$WORKSPACE_DIR/MEMORY.md"
fi

# --- Fix permissions ---
chown -R 1000:1000 "$OC_CONFIG_DIR"

# --- Clean up stale script copies from old layout ---
for script_name in "${SCRIPT_NAMES[@]}"; do
    chmod +x "$SCRIPT_DIR/$script_name" 2>/dev/null || true
    # Remove stale copies that used to live in OC_ROOT_DIR
    stale="$OC_ROOT_DIR/$script_name"
    if [ -f "$stale" ] && [ "$script_name" != "self-update.sh" ]; then
        rm -f "$stale"
    fi
done

echo "Applied OpenClaw infra assets from $OC_REPO_DIR to $OC_ROOT_DIR"
echo "Repo-managed scripts should be run from $SCRIPT_DIR"
