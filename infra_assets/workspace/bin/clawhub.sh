#!/usr/bin/env bash
set -euo pipefail

workspace_dir="${CLAWHUB_WORKDIR:-${OPENCLAW_WORKSPACE_DIR:-$HOME/.openclaw/workspace}}"
config_path="${CLAWHUB_CONFIG_PATH:-$HOME/.openclaw/clawhub/config.json}"

mkdir -p "$workspace_dir" "$(dirname "$config_path")"

export CLAWHUB_WORKDIR="$workspace_dir"
export CLAWHUB_CONFIG_PATH="$config_path"
export CLAWHUB_DISABLE_TELEMETRY="${CLAWHUB_DISABLE_TELEMETRY:-1}"

if command -v clawhub >/dev/null 2>&1; then
    exec clawhub "$@"
fi

exec npx --yes clawhub "$@"