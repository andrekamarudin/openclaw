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

INFISICAL_DOMAIN="${INFISICAL_DOMAIN:-}"
if [ -z "$INFISICAL_DOMAIN" ]; then
    echo "INFISICAL_DOMAIN is not set; skipping nginx enablement"
    exit 0
fi

CERT_PATH="/etc/letsencrypt/live/$INFISICAL_DOMAIN/fullchain.pem"

if [ ! -f "$CERT_PATH" ]; then
    certbot --nginx -d "$INFISICAL_DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email --redirect
fi

bash "$OC_REPO_DIR/infra_assets/scripts/apply-infra-assets.sh"