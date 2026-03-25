#!/usr/bin/env bash
set -euo pipefail

# Deploy / update Postiz on Contabo VPS.
# Runs in its own compose project, separate from the OpenClaw stack.

OC_REPO_DIR="${OC_REPO_DIR:-/opt/src/my_openclaw}"
POSTIZ_DIR="${POSTIZ_DIR:-/opt/postiz}"
CONFIG_DIR="${CONFIG_DIR:-/opt/config}"

SOURCE_COMPOSE="$OC_REPO_DIR/infra_assets/compose/docker-compose.postiz.yml"
SOURCE_DYNCONFIG_DIR="$OC_REPO_DIR/infra_assets/compose/dynamicconfig"
SOURCE_ENV_EXAMPLE="$OC_REPO_DIR/infra_assets/config/postiz.env.example"
SOURCE_COMPOSE_ENV_EXAMPLE="$OC_REPO_DIR/infra_assets/config/postiz-compose.env.example"
TARGET_COMPOSE="$POSTIZ_DIR/docker-compose.yml"
TARGET_DYNCONFIG_DIR="$POSTIZ_DIR/dynamicconfig"
TARGET_ENV="$CONFIG_DIR/postiz.env"
TARGET_COMPOSE_ENV="$POSTIZ_DIR/.env"

# -- Validate sources exist --------------------------------------------------
for f in "$SOURCE_COMPOSE" "$SOURCE_ENV_EXAMPLE"; do
    if [ ! -f "$f" ]; then
        echo "Missing source file: $f" >&2
        exit 1
    fi
done

# -- Ensure directories exist ------------------------------------------------
mkdir -p "$POSTIZ_DIR" "$TARGET_DYNCONFIG_DIR" "$CONFIG_DIR"

# -- Copy compose + dynamic config -------------------------------------------
cp "$SOURCE_COMPOSE" "$TARGET_COMPOSE"
cp -r "$SOURCE_DYNCONFIG_DIR/"* "$TARGET_DYNCONFIG_DIR/" 2>/dev/null || true

# -- Seed env file if missing -------------------------------------------------
NEEDS_CONFIG=false
if [ ! -f "$TARGET_ENV" ]; then
    cp "$SOURCE_ENV_EXAMPLE" "$TARGET_ENV"
    NEEDS_CONFIG=true
fi
if [ ! -f "$TARGET_COMPOSE_ENV" ]; then
    cp "$SOURCE_COMPOSE_ENV_EXAMPLE" "$TARGET_COMPOSE_ENV"
    NEEDS_CONFIG=true
fi
if [ "$NEEDS_CONFIG" = true ]; then
    echo "Created config files from examples — edit them before starting!"
    echo "  $TARGET_ENV        — app config (JWT_SECRET, DATABASE_URL, social keys)"
    echo "  $TARGET_COMPOSE_ENV — DB passwords for compose (POSTIZ_DB_PASSWORD, TEMPORAL_DB_PASSWORD)"
    exit 0
fi

# -- Bring up Postiz stack ----------------------------------------------------
cd "$POSTIZ_DIR"

docker compose pull
docker compose up -d

echo "Postiz deploy complete — access at $(grep '^MAIN_URL=' "$TARGET_ENV" | cut -d= -f2-) (once DNS and nginx are configured)"
