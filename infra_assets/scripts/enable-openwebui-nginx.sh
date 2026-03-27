#!/usr/bin/env bash
set -euo pipefail

OC_REPO_DIR="${OC_REPO_DIR:-/opt/src/openclaw}"

bash "$OC_REPO_DIR/openwebui/scripts/enable-openwebui-nginx.sh"
