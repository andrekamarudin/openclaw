#!/usr/bin/env bash
set -euo pipefail

# Sync repo-managed OpenClaw assets to /opt/openclaw and /root/.openclaw on the VPS.
# Run this from the VPS after pulling the latest openclaw repo.

OC_ROOT_DIR="${OC_ROOT_DIR:-/opt/openclaw}"
OC_REPO_DIR="${OC_REPO_DIR:-/opt/src/openclaw}"
OC_CONFIG_DIR="${OC_CONFIG_DIR:-/root/.openclaw}"
OPENCLAW_INFRA_DIR="$OC_REPO_DIR/openclaw-infra"
OPENCLAW_SCRIPT_DIR="$OPENCLAW_INFRA_DIR/scripts"

SOURCE_COMPOSE_FILE="$OPENCLAW_INFRA_DIR/compose/docker-compose.yml"
TARGET_COMPOSE_FILE="$OC_ROOT_DIR/docker-compose.yml"

SOURCE_BUILD_COMPOSE_FILE="$OPENCLAW_INFRA_DIR/compose/docker-compose.build.yml"
TARGET_BUILD_COMPOSE_FILE="$OC_ROOT_DIR/docker-compose.build.yml"

OPENCLAW_SCRIPT_NAMES=(
    apply-openclaw-infra.sh
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
SELF_UPDATE_SRC="$OPENCLAW_SCRIPT_DIR/self-update.sh"
SELF_UPDATE_DST="$OC_ROOT_DIR/self-update.sh"
if [ -f "$SELF_UPDATE_SRC" ]; then
    cp "$SELF_UPDATE_SRC" "$SELF_UPDATE_DST"
    chmod +x "$SELF_UPDATE_DST"
fi

# --- OpenClaw config ---
OC_CONFIG_FILE="$OC_CONFIG_DIR/openclaw.json"
OC_CONFIG_SRC="$OPENCLAW_INFRA_DIR/config/openclaw.json"
if [ -f "$OC_CONFIG_SRC" ]; then
    mkdir -p "$OC_CONFIG_DIR"
    if [ -f "$OC_ROOT_DIR/.env" ]; then
        set -a
        # shellcheck disable=SC1091
        . "$OC_ROOT_DIR/.env"
        set +a
    fi
    envsubst < "$OC_CONFIG_SRC" > "$OC_CONFIG_FILE"
    echo "Deployed openclaw.json from repo (secrets injected from .env)"
fi

# --- Workspace files ---
WORKSPACE_DIR="$OC_CONFIG_DIR/workspace"
WORKSPACE_SRC="$OPENCLAW_INFRA_DIR/workspace"
mkdir -p "$WORKSPACE_DIR"

if [ -f "$WORKSPACE_SRC/AGENTS.md" ]; then
    cp "$WORKSPACE_SRC/AGENTS.md" "$WORKSPACE_DIR/AGENTS.md"
fi
if [ -f "$WORKSPACE_SRC/MEMORY.md" ]; then
    cp "$WORKSPACE_SRC/MEMORY.md" "$WORKSPACE_DIR/MEMORY.md"
fi
if [ -f "$WORKSPACE_SRC/DEV-OPERATIONS.md" ]; then
    cp "$WORKSPACE_SRC/DEV-OPERATIONS.md" "$WORKSPACE_DIR/DEV-OPERATIONS.md"
fi
if [ -d "$WORKSPACE_SRC/bin" ]; then
    mkdir -p "$WORKSPACE_DIR/bin"
    cp -R "$WORKSPACE_SRC/bin/." "$WORKSPACE_DIR/bin/"
    find "$WORKSPACE_DIR/bin" -type f -name '*.sh' -exec chmod +x {} +
fi
if [ -d "$WORKSPACE_SRC/skills" ]; then
    mkdir -p "$WORKSPACE_DIR/skills"
    cp -R "$WORKSPACE_SRC/skills/." "$WORKSPACE_DIR/skills/"
fi

# --- Fix permissions ---
chown -R 1000:1000 "$OC_CONFIG_DIR"

# --- Clean up stale script copies from old layout ---
for script_name in "${OPENCLAW_SCRIPT_NAMES[@]}"; do
    chmod +x "$OPENCLAW_SCRIPT_DIR/$script_name" 2>/dev/null || true
    stale="$OC_ROOT_DIR/$script_name"
    if [ -f "$stale" ] && [ "$script_name" != "self-update.sh" ]; then
        rm -f "$stale"
    fi
done

echo "Applied OpenClaw repo assets from $OC_REPO_DIR to $OC_ROOT_DIR"
echo "Repo-managed scripts should be run from $OPENCLAW_SCRIPT_DIR"