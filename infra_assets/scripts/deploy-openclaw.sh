#!/usr/bin/env bash
set -euo pipefail

# Deploy OpenClaw: pull repo, apply infra assets, pull latest image, restart.
# This is the image-based deploy (no source build).

OC_REPO_DIR="${OC_REPO_DIR:-/opt/src/my_openclaw}"

bash "$OC_REPO_DIR/openclaw-infra/scripts/deploy-openclaw.sh"
