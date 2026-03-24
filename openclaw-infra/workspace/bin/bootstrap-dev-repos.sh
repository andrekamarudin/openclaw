#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
ghgit="$script_dir/ghgit.sh"
dev_root="${OPENCLAW_DEV_ROOT:-$HOME/.openclaw/workspace/dev}"
main_root="$dev_root/main"
worktrees_root="$dev_root/worktrees"

mkdir -p "$main_root" "$worktrees_root"

git config --global user.name "${GIT_AUTHOR_NAME:-Andre Kamarudin}"
git config --global user.email "${GIT_AUTHOR_EMAIL:-andre.kamarudin@gmail.com}"

clone_or_update() {
    local remote_url="$1"
    local dest="$2"

    if [ ! -d "$dest/.git" ]; then
        "$ghgit" clone "$remote_url" "$dest"
    else
        "$ghgit" -C "$dest" fetch --all --prune
    fi
}

if [ -n "${GITHUB_VIKUNJA_CORE_PUSH_REPO:-}" ]; then
    clone_or_update "https://github.com/${GITHUB_VIKUNJA_CORE_PUSH_REPO}.git" "$main_root/vikunja"
    git -C "$main_root/vikunja" remote remove upstream >/dev/null 2>&1 || true
    git -C "$main_root/vikunja" remote add upstream "https://github.com/${GITHUB_VIKUNJA_CORE_REPO:-go-vikunja/vikunja}.git"
else
    clone_or_update "https://github.com/${GITHUB_VIKUNJA_CORE_REPO:-go-vikunja/vikunja}.git" "$main_root/vikunja"
fi

if [ -n "${GITHUB_TOKEN:-}" ]; then
    clone_or_update "https://github.com/${GITHUB_VIKUNJA_WRAPPER_REPO:-andrekamarudin/vikunja_wrapper}.git" "$main_root/vikunja_wrapper"
else
    echo "Skipping vikunja_wrapper clone: GITHUB_TOKEN is not set." >&2
fi

echo "Main checkouts ready under $main_root"
echo "Create concurrent worktrees under $worktrees_root with create-worktree.sh"