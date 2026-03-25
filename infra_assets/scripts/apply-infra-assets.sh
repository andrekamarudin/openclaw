#!/usr/bin/env bash
set -euo pipefail

# Sync repo-managed infra files to /opt/openclaw and /root/.openclaw on the VPS.
# Run this from the VPS after pulling the latest my_openclaw repo.

OC_ROOT_DIR="${OC_ROOT_DIR:-/opt/openclaw}"
OC_REPO_DIR="${OC_REPO_DIR:-/opt/src/my_openclaw}"
SCRIPT_DIR="$OC_REPO_DIR/infra_assets/scripts"

SCRIPT_NAMES=(
    apply-infra-assets.sh
    deploy-homarr.sh
    enable-homarr-nginx.sh
    deploy-uptime-kuma.sh
    enable-uptime-kuma-nginx.sh
    deploy-vikunja.sh
    enable-vikunja-nginx.sh
)

bash "$OC_REPO_DIR/openclaw-infra/scripts/apply-openclaw-infra.sh"

if [ -f "$OC_ROOT_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    . "$OC_ROOT_DIR/.env"
    set +a
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

# --- Nginx site for Vikunja ---
VIKUNJA_DOMAIN="${VIKUNJA_DOMAIN:-}"
VIKUNJA_NGINX_HTTP_SRC="$OC_REPO_DIR/infra_assets/nginx/vikunja-http.conf"
VIKUNJA_NGINX_HTTPS_SRC="$OC_REPO_DIR/infra_assets/nginx/vikunja-https.conf"

if [ -n "$VIKUNJA_DOMAIN" ] && [ -f "$VIKUNJA_NGINX_HTTP_SRC" ]; then
    NGINX_SITE_AVAILABLE="/etc/nginx/sites-available/$VIKUNJA_DOMAIN.conf"
    NGINX_SITE_ENABLED="/etc/nginx/sites-enabled/$VIKUNJA_DOMAIN.conf"
    CERT_DIR="/etc/letsencrypt/live/$VIKUNJA_DOMAIN"

    mkdir -p /etc/nginx/sites-available /etc/nginx/sites-enabled

    if [ -f "$CERT_DIR/fullchain.pem" ] && [ -f "$CERT_DIR/privkey.pem" ] && [ -f "$VIKUNJA_NGINX_HTTPS_SRC" ]; then
        envsubst '${VIKUNJA_DOMAIN}' < "$VIKUNJA_NGINX_HTTPS_SRC" > "$NGINX_SITE_AVAILABLE"
    else
        envsubst '${VIKUNJA_DOMAIN}' < "$VIKUNJA_NGINX_HTTP_SRC" > "$NGINX_SITE_AVAILABLE"
    fi

    ln -sfn "$NGINX_SITE_AVAILABLE" "$NGINX_SITE_ENABLED"

    if command -v nginx >/dev/null 2>&1; then
        nginx -t
        systemctl reload nginx
        echo "Deployed nginx site for $VIKUNJA_DOMAIN"
    fi
fi

# --- Clean up stale script copies from old layout ---
for script_name in "${SCRIPT_NAMES[@]}"; do
    chmod +x "$SCRIPT_DIR/$script_name" 2>/dev/null || true
    # Remove stale copies that used to live in OC_ROOT_DIR
    stale="$OC_ROOT_DIR/$script_name"
    if [ -f "$stale" ] && [ "$script_name" != "self-update.sh" ]; then
        rm -f "$stale"
    fi
done

echo "Applied shared infra assets from $OC_REPO_DIR"
echo "OpenClaw and Open WebUI assets are sourced from /opt/src/my_openclaw/openclaw-infra and /opt/src/my_openclaw/openwebui"
