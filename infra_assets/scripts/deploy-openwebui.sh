#!/usr/bin/env bash
set -euo pipefail

# Deploy Open WebUI: pull repo, apply infra assets, pull latest image, start services.

OC_REPO_DIR="${OC_REPO_DIR:-/opt/src/openclaw}"

bash "$OC_REPO_DIR/openwebui/scripts/deploy-openwebui.sh"
