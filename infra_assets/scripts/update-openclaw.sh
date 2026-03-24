#!/usr/bin/env bash
set -euo pipefail

# Pull the latest OpenClaw image and restart.
# Quick update without touching infra assets or repo.

OC_REPO_DIR="${OC_REPO_DIR:-/opt/src/my_openclaw}"

bash "$OC_REPO_DIR/openclaw-infra/scripts/update-openclaw.sh"
