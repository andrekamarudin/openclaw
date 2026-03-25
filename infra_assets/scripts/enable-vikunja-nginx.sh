#!/usr/bin/env bash
set -euo pipefail

OC_ROOT_DIR="${OC_ROOT_DIR:-/opt/openclaw}"
OC_REPO_DIR="${OC_REPO_DIR:-/opt/src/my_openclaw}"

if [ -f "$OC_ROOT_DIR/.env" ]; then
    set -a
    # shellcheck disable=SC1091
    . "$OC_ROOT_DIR/.env"
    set +a
fi

VIKUNJA_DOMAIN="${VIKUNJA_DOMAIN:-}"
if [ -z "$VIKUNJA_DOMAIN" ]; then
    echo "VIKUNJA_DOMAIN is not set; skipping nginx enablement"
    exit 0
fi

CERT_PATH="/etc/letsencrypt/live/$VIKUNJA_DOMAIN/fullchain.pem"

if [ ! -f "$CERT_PATH" ]; then
    certbot --nginx -d "$VIKUNJA_DOMAIN" --non-interactive --agree-tos --register-unsafely-without-email --redirect
fi

bash "$OC_REPO_DIR/infra_assets/scripts/apply-infra-assets.sh"
