#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <wrapper|fast|core-build>" >&2
    exit 1
fi

target="$1"
script_dir="$(cd "$(dirname "$0")" && pwd)"
key_file="$($script_dir/setup-racknerd-ssh.sh)"
known_hosts="${OPENCLAW_DEV_ROOT:-$HOME/.openclaw/workspace/dev}/.ssh/known_hosts"

case "$target" in
    wrapper)
        remote_script="${RACKNERD_DEPLOY_WRAPPER_SCRIPT:-/opt/src/vikunja_wrapper/infra_assets/scripts/deploy-wrapper.sh}"
        ;;
    fast)
        remote_script="${RACKNERD_DEPLOY_FAST_SCRIPT:-/opt/src/vikunja_wrapper/infra_assets/scripts/deploy-fast.sh}"
        ;;
    core-build)
        remote_script="${RACKNERD_DEPLOY_BUILD_CORE_SCRIPT:-/opt/src/vikunja_wrapper/infra_assets/scripts/deploy-build-vikunja.sh}"
        ;;
    *)
        echo "Unknown target: $target" >&2
        exit 1
        ;;
esac

exec ssh \
    -i "$key_file" \
    -o IdentitiesOnly=yes \
    -o StrictHostKeyChecking=yes \
    -o UserKnownHostsFile="$known_hosts" \
    -p "${RACKNERD_SSH_PORT:-22}" \
    "${RACKNERD_SSH_USER:-root}@${RACKNERD_SSH_HOST}" \
    "bash '$remote_script'"