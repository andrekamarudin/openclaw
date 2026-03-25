#!/usr/bin/env bash
set -euo pipefail

# Deploy / update Karakeep on Contabo VPS.
# Runs in its own compose project, separate from the OpenClaw stack.

OC_REPO_DIR="${OC_REPO_DIR:-/opt/src/my_openclaw}"
KARAKEEP_DIR="${KARAKEEP_DIR:-/opt/karakeep}"
CONFIG_DIR="${CONFIG_DIR:-/opt/config}"

SOURCE_COMPOSE="$OC_REPO_DIR/infra_assets/compose/docker-compose.karakeep.yml"
SOURCE_ENV_EXAMPLE="$OC_REPO_DIR/infra_assets/config/karakeep.env.example"
SOURCE_WRAPPER_ENV_EXAMPLE="$OC_REPO_DIR/infra_assets/config/karakeep_wrapper.env.example"
TARGET_COMPOSE="$KARAKEEP_DIR/docker-compose.yml"
TARGET_ENV="$KARAKEEP_DIR/.env"
TARGET_WRAPPER_ENV="$CONFIG_DIR/karakeep_wrapper.env"

# -- Validate sources exist -----------------------------------------------
for f in "$SOURCE_COMPOSE" "$SOURCE_ENV_EXAMPLE"; do
    if [ ! -f "$f" ]; then
        echo "Missing source file: $f" >&2
        exit 1
    fi
done

# -- Ensure directories exist ---------------------------------------------
mkdir -p "$KARAKEEP_DIR" "$CONFIG_DIR" /opt/src

# -- Validate wrapper source exists ----------------------------------------
if [ ! -d /opt/src/karakeep_wrapper ]; then
    echo "Missing wrapper source checkout: /opt/src/karakeep_wrapper" >&2
    echo "Sync the wrapper source to the VPS before deploying." >&2
    exit 1
fi

# -- Copy compose ----------------------------------------------------------
cp "$SOURCE_COMPOSE" "$TARGET_COMPOSE"

# -- Seed env file if missing ----------------------------------------------
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
    echo "  $TARGET_ENV         — Karakeep config"
    echo "  $TARGET_WRAPPER_ENV — wrapper config (API keys, LLM, Whop)"
    exit 0
fi

# -- Fetch secrets from Infisical if agent is configured -------------------
INFISICAL_AGENT_ENV="${INFISICAL_AGENT_ENV:-/opt/config/infisical-agent.env}"
if [ -f "$INFISICAL_AGENT_ENV" ] && [ -f /opt/config/infisical-env.sh ]; then
    source /opt/config/infisical-env.sh
    infisical_fetch contabo-karakeep "$TARGET_ENV" prod || true
    # Merge wrapper-specific secrets into wrapper env
    infisical_fetch contabo-karakeep "$TARGET_WRAPPER_ENV" prod || true
fi

# -- Bring up Karakeep stack -----------------------------------------------
cd "$KARAKEEP_DIR"

docker compose pull --ignore-buildable
docker compose up -d --build

echo "Karakeep deploy complete — access at https://karakeep.bytesizeprotip.com"
