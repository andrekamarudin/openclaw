#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <vikunja|vikunja_wrapper> <branch>" >&2
    exit 1
fi

repo_name="$1"
branch="$2"
dev_root="${OPENCLAW_DEV_ROOT:-$HOME/.openclaw/workspace/dev}"
main_repo="$dev_root/main/$repo_name"
target_dir="$dev_root/worktrees/$repo_name/$branch"

if [ ! -d "$main_repo/.git" ]; then
    echo "Main repo checkout missing: $main_repo" >&2
    exit 1
fi

mkdir -p "$(dirname "$target_dir")"
git -C "$main_repo" fetch --all --prune
git -C "$main_repo" worktree add -B "$branch" "$target_dir" "origin/$(git -C "$main_repo" rev-parse --abbrev-ref HEAD 2>/dev/null || echo main)" >/dev/null 2>&1 || \
git -C "$main_repo" worktree add -B "$branch" "$target_dir"

echo "$target_dir"