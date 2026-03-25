#!/usr/bin/env bash
set -euo pipefail

# Deploy / update Karakeep on Contabo VPS.
# Runs in its own compose project, separate from the OpenClaw stack.

OC_REPO_DIR="${OC_REPO_DIR:-/opt/src/my_openclaw}"
KARAKEEP_DIR="${KARAKEEP_DIR:-/opt/karakeep}"
CONFIG_DIR="${CONFIG_DIR:-/opt/config}"

SOURCE_COMPOSE="$OC_REPO_DIR/infra_assets/compose/docker-compose.karakeep.yml"
SOURCE_ENV_EXAMPLE="$OC_REPO_DIR/infra_assets/config/karakeep.env.example"
TARGET_COMPOSE="$KARAKEEP_DIR/docker-compose.yml"
TARGET_ENV="$KARAKEEP_DIR/.env"

# -- Validate sources exist -----------------------------------------------
for f in "$SOURCE_COMPOSE" "$SOURCE_ENV_EXAMPLE"; do
    if [ ! -f "$f" ]; then
        echo "Missing source file: $f" >&2
        exit 1
    fi
done

# -- Ensure directories exist ---------------------------------------------
mkdir -p "$KARAKEEP_DIR" "$CONFIG_DIR"

# -- Copy compose ----------------------------------------------------------
cp "$SOURCE_COMPOSE" "$TARGET_COMPOSE"

# -- Seed env file if missing ----------------------------------------------
if [ ! -f "$TARGET_ENV" ]; then
    cp "$SOURCE_ENV_EXAMPLE" "$TARGET_ENV"
    echo "Created config file from example — edit it before starting!"
    echo "  $TARGET_ENV"
    exit 0
fi

# -- Fetch secrets from Infisical if agent is configured -------------------
INFISICAL_AGENT_ENV="${INFISICAL_AGENT_ENV:-/opt/config/infisical-agent.env}"
if [ -f "$INFISICAL_AGENT_ENV" ] && [ -f /opt/config/infisical-env.sh ]; then
    source /opt/config/infisical-env.sh
    infisical_fetch contabo-karakeep "$TARGET_ENV" prod || true
fi

# -- Bring up Karakeep stack -----------------------------------------------
cd "$KARAKEEP_DIR"

docker compose pull
docker compose up -d

echo "Karakeep deploy complete — access at https://karakeep.bytesizeprotip.com"
