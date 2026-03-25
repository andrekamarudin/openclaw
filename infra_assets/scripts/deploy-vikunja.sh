#!/usr/bin/env bash
set -euo pipefail

# Deploy / update Vikunja + wrapper on Contabo VPS.
# Runs in its own compose project, separate from the OpenClaw stack.

OC_REPO_DIR="${OC_REPO_DIR:-/opt/src/my_openclaw}"
VIKUNJA_DIR="${VIKUNJA_DIR:-/opt/vikunja}"
CONFIG_DIR="${CONFIG_DIR:-/opt/config}"

SOURCE_COMPOSE="$OC_REPO_DIR/infra_assets/compose/docker-compose.vikunja.yml"
SOURCE_ENV_EXAMPLE="$OC_REPO_DIR/infra_assets/config/vikunja.env.example"
SOURCE_WRAPPER_ENV_EXAMPLE="$OC_REPO_DIR/infra_assets/config/vikunja_wrapper.env.example"
TARGET_COMPOSE="$VIKUNJA_DIR/docker-compose.yml"
TARGET_ENV="$VIKUNJA_DIR/.env"
TARGET_WRAPPER_ENV="$CONFIG_DIR/vikunja_wrapper.env"

# -- Validate sources exist --------------------------------------------------
for f in "$SOURCE_COMPOSE" "$SOURCE_ENV_EXAMPLE"; do
    if [ ! -f "$f" ]; then
        echo "Missing source file: $f" >&2
        exit 1
    fi
done

# -- Ensure directories exist ------------------------------------------------
mkdir -p "$VIKUNJA_DIR" "$CONFIG_DIR"

# -- Copy compose -------------------------------------------------------------
cp "$SOURCE_COMPOSE" "$TARGET_COMPOSE"

# -- Seed env files if missing ------------------------------------------------
NEEDS_CONFIG=false
if [ ! -f "$TARGET_ENV" ]; then
    cp "$SOURCE_ENV_EXAMPLE" "$TARGET_ENV"
    NEEDS_CONFIG=true
fi
if [ ! -f "$TARGET_WRAPPER_ENV" ]; then
    cp "$SOURCE_WRAPPER_ENV_EXAMPLE" "$TARGET_WRAPPER_ENV"
    NEEDS_CONFIG=true
fi
if [ "$NEEDS_CONFIG" = true ]; then
    echo "Created config files from examples — edit them before starting!"
    echo "  $TARGET_ENV         — Vikunja + DB config"
    echo "  $TARGET_WRAPPER_ENV — wrapper config (API keys, LLM, etc.)"
    exit 0
fi

# -- Bring up Vikunja stack ---------------------------------------------------
cd "$VIKUNJA_DIR"

docker compose pull
docker compose up -d --build

echo "Vikunja deploy complete — access at https://tasks.bytesizeprotip.com (once DNS and nginx are configured)"
