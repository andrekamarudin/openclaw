#!/usr/bin/env bash
set -euo pipefail

# Reuses the same deploy key as RackNerd (already decoded by setup-racknerd-ssh.sh).
# Run setup-racknerd-ssh.sh first to ensure the key exists.

key_dir="${OPENCLAW_DEV_ROOT:-$HOME/.openclaw/workspace/dev}/.ssh"
key_file="$key_dir/racknerd_ed25519"
known_hosts="$key_dir/known_hosts"

if [ ! -f "$key_file" ]; then
    script_dir="$(cd "$(dirname "$0")" && pwd)"
    "$script_dir/setup-racknerd-ssh.sh" >/dev/null
fi

if [ -n "${N8N_SSH_HOST:-}" ]; then
    mkdir -p "$key_dir"
    ssh-keyscan -p "${N8N_SSH_PORT:-22}" -H "$N8N_SSH_HOST" >> "$known_hosts" 2>/dev/null || true
    sort -u "$known_hosts" -o "$known_hosts"
    chmod 644 "$known_hosts"
fi

echo "$key_file"
