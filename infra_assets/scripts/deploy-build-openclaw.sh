#!/usr/bin/env bash
set -euo pipefail

# Deploy OpenClaw from source: pull both repos, build image, restart.
# Use this when you have local app code changes in your openclaw fork.
# WARNING: Building OpenClaw from source requires significant RAM (~4GB+).

OC_REPO_DIR="${OC_REPO_DIR:-/opt/src/openclaw}"

bash "$OC_REPO_DIR/openclaw-infra/scripts/deploy-build-openclaw.sh"
