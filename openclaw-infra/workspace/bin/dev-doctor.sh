#!/usr/bin/env bash
set -euo pipefail

echo "OpenClaw dev doctor"
echo "==================="
echo "OPENCLAW_DEV_ROOT=${OPENCLAW_DEV_ROOT:-$HOME/.openclaw/workspace/dev}"

if [ -n "${GITHUB_TOKEN:-}" ]; then
    echo "GitHub token: present"
else
    echo "GitHub token: missing (private repo clone/issues API unavailable)"
fi

echo "Vikunja core repo: ${GITHUB_VIKUNJA_CORE_REPO:-go-vikunja/vikunja}"
echo "Vikunja core push repo: ${GITHUB_VIKUNJA_CORE_PUSH_REPO:-<not set>}"
echo "Vikunja wrapper repo: ${GITHUB_VIKUNJA_WRAPPER_REPO:-andrekamarudin/vikunja_wrapper}"

if [ -n "${RACKNERD_DEPLOY_KEY_B64:-}" ]; then
    echo "RackNerd deploy key: present"
else
    echo "RackNerd deploy key: missing"
fi

echo "RackNerd host: ${RACKNERD_SSH_USER:-root}@${RACKNERD_SSH_HOST:-<missing>}"

if [ -n "${GITHUB_TOKEN:-}" ]; then
    if curl -fsSL -H "Accept: application/vnd.github+json" -H "Authorization: Bearer ${GITHUB_TOKEN}" https://api.github.com/user >/dev/null; then
        echo "GitHub API: OK"
    else
        echo "GitHub API: FAILED"
    fi
fi