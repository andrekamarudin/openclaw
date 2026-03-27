#!/usr/bin/env bash
set -euo pipefail

OC_ROOT_DIR="${OC_ROOT_DIR:-/opt/openclaw}"
OC_REPO_DIR="${OC_REPO_DIR:-/opt/src/openclaw}"

if [ -f "$OC_ROOT_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    . "$OC_ROOT_DIR/.env"
    set +a
fi

UPTIME_KUMA_DOMAIN="${UPTIME_KUMA_DOMAIN:-}"
if [ -z "$UPTIME_KUMA_DOMAIN" ]; then
    echo "UPTIME_KUMA_DOMAIN is not set; skipping nginx enablement"
    exit 0
fi

CERT_PATH="/etc/letsencrypt/live/$UPTIME_KUMA_DOMAIN/fullchain.pem"

if [ ! -f "$CERT_PATH" ]; then
    certbot --nginx -d "$UPTIME_KUMA_DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email --redirect
fi

bash "$OC_REPO_DIR/infra_assets/scripts/apply-infra-assets.sh"
