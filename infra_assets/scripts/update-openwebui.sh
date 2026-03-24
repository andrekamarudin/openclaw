#!/usr/bin/env bash
set -euo pipefail

# Pull the latest Open WebUI image and restart.
# Quick update without touching infra assets or repo.

OC_REPO_DIR="${OC_REPO_DIR:-/opt/src/my_openclaw}"

bash "$OC_REPO_DIR/openwebui/scripts/update-openwebui.sh"
