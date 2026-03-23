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
    deploy-openwebui.sh
    enable-openwebui-nginx.sh
    update-openwebui.sh
    deploy-homarr.sh
    enable-homarr-nginx.sh
    deploy-uptime-kuma.sh
    enable-uptime-kuma-nginx.sh
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
    envsubst < "$OC_CONFIG_SRC" > "$OC_CONFIG_FILE"
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

# --- Nginx site for Open WebUI ---
OPENWEBUI_DOMAIN="${OPENWEBUI_DOMAIN:-}"
OPENWEBUI_BIND_PORT="${OPENWEBUI_BIND_PORT:-3000}"
OPENWEBUI_NGINX_HTTP_SRC="$OC_REPO_DIR/infra_assets/nginx/openwebui-http.conf"
OPENWEBUI_NGINX_HTTPS_SRC="$OC_REPO_DIR/infra_assets/nginx/openwebui-https.conf"

if [ -n "$OPENWEBUI_DOMAIN" ] && [ -f "$OPENWEBUI_NGINX_HTTP_SRC" ]; then
    NGINX_SITE_AVAILABLE="/etc/nginx/sites-available/$OPENWEBUI_DOMAIN.conf"
    NGINX_SITE_ENABLED="/etc/nginx/sites-enabled/$OPENWEBUI_DOMAIN.conf"
    CERT_DIR="/etc/letsencrypt/live/$OPENWEBUI_DOMAIN"

    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

    if [ -f "$CERT_DIR/fullchain.pem" ] && [ -f "$CERT_DIR/privkey.pem" ] && [ -f "$OPENWEBUI_NGINX_HTTPS_SRC" ]; then
        envsubst '${OPENWEBUI_DOMAIN} ${OPENWEBUI_BIND_PORT}' < "$OPENWEBUI_NGINX_HTTPS_SRC" > "$NGINX_SITE_AVAILABLE"
    else
        envsubst '${OPENWEBUI_DOMAIN} ${OPENWEBUI_BIND_PORT}' < "$OPENWEBUI_NGINX_HTTP_SRC" > "$NGINX_SITE_AVAILABLE"
    fi

    ln -sfn "$NGINX_SITE_AVAILABLE" "$NGINX_SITE_ENABLED"

    if command -v nginx >/dev/null 2>&1; then
        nginx -t
        systemctl reload nginx
        echo "Deployed nginx site for $OPENWEBUI_DOMAIN"
    fi
fi

# --- Nginx site for Homarr ---
HOMARR_DOMAIN="${HOMARR_DOMAIN:-}"
HOMARR_NGINX_HTTP_SRC="$OC_REPO_DIR/infra_assets/nginx/homarr-http.conf"
HOMARR_NGINX_HTTPS_SRC="$OC_REPO_DIR/infra_assets/nginx/homarr-https.conf"

if [ -n "$HOMARR_DOMAIN" ] && [ -f "$HOMARR_NGINX_HTTP_SRC" ]; then
    NGINX_SITE_AVAILABLE="/etc/nginx/sites-available/$HOMARR_DOMAIN.conf"
    NGINX_SITE_ENABLED="/etc/nginx/sites-enabled/$HOMARR_DOMAIN.conf"
    CERT_DIR="/etc/letsencrypt/live/$HOMARR_DOMAIN"

    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

    if [ -f "$CERT_DIR/fullchain.pem" ] && [ -f "$CERT_DIR/privkey.pem" ] && [ -f "$HOMARR_NGINX_HTTPS_SRC" ]; then
        envsubst '${HOMARR_DOMAIN}' < "$HOMARR_NGINX_HTTPS_SRC" > "$NGINX_SITE_AVAILABLE"
    else
        envsubst '${HOMARR_DOMAIN}' < "$HOMARR_NGINX_HTTP_SRC" > "$NGINX_SITE_AVAILABLE"
    fi

    ln -sfn "$NGINX_SITE_AVAILABLE" "$NGINX_SITE_ENABLED"

    if command -v nginx >/dev/null 2>&1; then
        nginx -t
        systemctl reload nginx
        echo "Deployed nginx site for $HOMARR_DOMAIN"
    fi
fi

# --- Nginx site for Uptime Kuma ---
UPTIME_KUMA_DOMAIN="${UPTIME_KUMA_DOMAIN:-}"
UPTIME_KUMA_NGINX_HTTP_SRC="$OC_REPO_DIR/infra_assets/nginx/uptime-kuma-http.conf"
UPTIME_KUMA_NGINX_HTTPS_SRC="$OC_REPO_DIR/infra_assets/nginx/uptime-kuma-https.conf"

if [ -n "$UPTIME_KUMA_DOMAIN" ] && [ -f "$UPTIME_KUMA_NGINX_HTTP_SRC" ]; then
    NGINX_SITE_AVAILABLE="/etc/nginx/sites-available/$UPTIME_KUMA_DOMAIN.conf"
    NGINX_SITE_ENABLED="/etc/nginx/sites-enabled/$UPTIME_KUMA_DOMAIN.conf"
    CERT_DIR="/etc/letsencrypt/live/$UPTIME_KUMA_DOMAIN"

    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

    if [ -f "$CERT_DIR/fullchain.pem" ] && [ -f "$CERT_DIR/privkey.pem" ] && [ -f "$UPTIME_KUMA_NGINX_HTTPS_SRC" ]; then
        envsubst '${UPTIME_KUMA_DOMAIN}' < "$UPTIME_KUMA_NGINX_HTTPS_SRC" > "$NGINX_SITE_AVAILABLE"
    else
        envsubst '${UPTIME_KUMA_DOMAIN}' < "$UPTIME_KUMA_NGINX_HTTP_SRC" > "$NGINX_SITE_AVAILABLE"
    fi

    ln -sfn "$NGINX_SITE_AVAILABLE" "$NGINX_SITE_ENABLED"

    if command -v nginx >/dev/null 2>&1; then
        nginx -t
        systemctl reload nginx
        echo "Deployed nginx site for $UPTIME_KUMA_DOMAIN"
    fi
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
