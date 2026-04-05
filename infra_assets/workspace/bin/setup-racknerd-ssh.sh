#!/usr/bin/env bash
set -euo pipefail

key_dir="${OPENCLAW_DEV_ROOT:-$HOME/.openclaw/workspace/dev}/.ssh"
key_file="$key_dir/racknerd_ed25519"
known_hosts="$key_dir/known_hosts"

if [ -z "${RACKNERD_DEPLOY_KEY_B64:-}" ]; then
    echo "Missing RACKNERD_DEPLOY_KEY_B64" >&2
    exit 1
fi

mkdir -p "$key_dir"
chmod 700 "$key_dir"

printf '%s' "$RACKNERD_DEPLOY_KEY_B64" | base64 -d > "$key_file"
chmod 600 "$key_file"

if [ -n "${RACKNERD_SSH_HOST:-}" ]; then
    ssh-keyscan -p "${RACKNERD_SSH_PORT:-22}" -H "$RACKNERD_SSH_HOST" >> "$known_hosts" 2>/dev/null || true
    sort -u "$known_hosts" -o "$known_hosts"
    chmod 644 "$known_hosts"
fi

echo "$key_file"