#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <owner/repo> <issue-number>" >&2
    exit 1
fi

repo="$1"
issue_number="$2"
url="https://api.github.com/repos/${repo}/issues/${issue_number}"

headers=(-H 'Accept: application/vnd.github+json')
if [ -n "${GITHUB_TOKEN:-}" ]; then
    headers+=(-H "Authorization: Bearer ${GITHUB_TOKEN}")
fi

curl -fsSL "${headers[@]}" "$url"