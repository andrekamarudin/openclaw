#!/usr/bin/env bash
# infisical-env.sh — Fetch secrets from Infisical and write to .env files
#
# Bootstrap: each VPS needs /opt/config/infisical-agent.env with:
#   INFISICAL_CLIENT_ID=<clientId>
#   INFISICAL_CLIENT_SECRET=<clientSecret>
#   INFISICAL_URL=https://knives.bytesizeprotip.com
#
# Usage:
#   source /opt/config/infisical-env.sh
#   infisical_fetch <project-slug> <output-env-path>
#
# Example:
#   infisical_fetch racknerd-vikunja /opt/vikunja/.env
#   infisical_fetch racknerd-modal   /opt/config/modal.env
set -euo pipefail

INFISICAL_AGENT_ENV="${INFISICAL_AGENT_ENV:-/opt/config/infisical-agent.env}"

_infisical_get_token() {
    local client_id="$1" client_secret="$2" url="$3"
    local resp
    resp=$(curl -sf -X POST "${url}/api/v1/auth/universal-auth/login" \
        -H "Content-Type: application/json" \
        -d "{\"clientId\":\"${client_id}\",\"clientSecret\":\"${client_secret}\"}")
    echo "$resp" | python3 -c "import sys,json; print(json.load(sys.stdin)['accessToken'])" 2>/dev/null \
        || echo "$resp" | grep -oP '"accessToken"\s*:\s*"\K[^"]+' 2>/dev/null \
        || { echo "ERROR: Failed to get Infisical token" >&2; return 1; }
}

_infisical_fetch_secrets() {
    local token="$1" url="$2" project_id="$3" env_slug="${4:-prod}"
    curl -sf "${url}/api/v3/secrets/raw?workspaceId=${project_id}&environment=${env_slug}&secretPath=/" \
        -H "Authorization: Bearer ${token}"
}

_infisical_resolve_project_id() {
    local token="$1" url="$2" project_name="$3" org_id="$4"
    local resp
    resp=$(curl -sf "${url}/api/v2/organizations/${org_id}/workspaces" \
        -H "Authorization: Bearer ${token}")
    echo "$resp" | python3 -c "
import sys, json
data = json.load(sys.stdin)
for ws in data.get('workspaces', []):
    if ws['name'] == '${project_name}':
        print(ws['id'])
        break
" 2>/dev/null
}

infisical_fetch() {
    local project_name="$1"
    local output_path="$2"
    local env_slug="${3:-prod}"

    if [ ! -f "$INFISICAL_AGENT_ENV" ]; then
        echo "ERROR: Agent config not found at $INFISICAL_AGENT_ENV" >&2
        echo "       Create it with INFISICAL_CLIENT_ID, INFISICAL_CLIENT_SECRET, INFISICAL_URL" >&2
        return 1
    fi

    # Load agent credentials
    set -a
    # shellcheck disable=SC1090
    . "$INFISICAL_AGENT_ENV"
    set +a

    local url="${INFISICAL_URL:?INFISICAL_URL not set in $INFISICAL_AGENT_ENV}"
    local client_id="${INFISICAL_CLIENT_ID:?INFISICAL_CLIENT_ID not set}"
    local client_secret="${INFISICAL_CLIENT_SECRET:?INFISICAL_CLIENT_SECRET not set}"
    local org_id="${INFISICAL_ORG_ID:-26dd1a0e-0187-4dc1-a970-8bea9361d1b2}"

    echo "  [infisical] Authenticating..."
    local token
    token=$(_infisical_get_token "$client_id" "$client_secret" "$url")

    echo "  [infisical] Resolving project: $project_name"
    local project_id
    project_id=$(_infisical_resolve_project_id "$token" "$url" "$project_name" "$org_id")
    if [ -z "$project_id" ]; then
        echo "ERROR: Project '$project_name' not found" >&2
        return 1
    fi

    echo "  [infisical] Fetching secrets from $project_name ($env_slug)..."
    local secrets_json
    secrets_json=$(_infisical_fetch_secrets "$token" "$url" "$project_id" "$env_slug")

    # Write secrets to .env file
    local output_dir
    output_dir=$(dirname "$output_path")
    mkdir -p "$output_dir"

    python3 -c "
import json, sys
data = json.load(sys.stdin)
secrets = data.get('secrets', [])
with open('${output_path}', 'w') as f:
    f.write('# Auto-generated from Infisical project: ${project_name}\n')
    f.write('# Environment: ${env_slug}\n')
    f.write('# DO NOT EDIT — managed by infisical-env.sh\n\n')
    for s in sorted(secrets, key=lambda x: x['secretKey']):
        key = s['secretKey']
        val = s['secretValue']
        # Quote values that contain spaces or special chars
        if any(c in val for c in ' \t\"\\\\#\$!') or not val:
            f.write(f'{key}=\"{val}\"\n')
        else:
            f.write(f'{key}={val}\n')
print(f'  [infisical] Wrote {len(secrets)} secrets to ${output_path}')
" <<< "$secrets_json"

    chmod 600 "$output_path"
}

# Convenience: fetch multiple projects into one merged .env
infisical_fetch_multi() {
    local output_path="$1"
    shift
    local project_names=("$@")

    if [ ! -f "$INFISICAL_AGENT_ENV" ]; then
        echo "ERROR: Agent config not found at $INFISICAL_AGENT_ENV" >&2
        return 1
    fi

    set -a
    # shellcheck disable=SC1090
    . "$INFISICAL_AGENT_ENV"
    set +a

    local url="${INFISICAL_URL:?}"
    local client_id="${INFISICAL_CLIENT_ID:?}"
    local client_secret="${INFISICAL_CLIENT_SECRET:?}"
    local org_id="${INFISICAL_ORG_ID:-26dd1a0e-0187-4dc1-a970-8bea9361d1b2}"

    local token
    token=$(_infisical_get_token "$client_id" "$client_secret" "$url")

    local output_dir
    output_dir=$(dirname "$output_path")
    mkdir -p "$output_dir"

    echo "# Auto-generated from Infisical" > "$output_path"
    echo "# Projects: ${project_names[*]}" >> "$output_path"
    echo "# DO NOT EDIT — managed by infisical-env.sh" >> "$output_path"
    echo "" >> "$output_path"

    local total=0
    for project_name in "${project_names[@]}"; do
        local project_id
        project_id=$(_infisical_resolve_project_id "$token" "$url" "$project_name" "$org_id")
        if [ -z "$project_id" ]; then
            echo "  WARNING: Project '$project_name' not found, skipping" >&2
            continue
        fi

        local secrets_json
        secrets_json=$(_infisical_fetch_secrets "$token" "$url" "$project_id" "prod")

        local count
        count=$(python3 -c "
import json, sys
data = json.load(sys.stdin)
secrets = data.get('secrets', [])
with open('${output_path}', 'a') as f:
    f.write(f'\n# --- ${project_name} ---\n')
    for s in sorted(secrets, key=lambda x: x['secretKey']):
        key = s['secretKey']
        val = s['secretValue']
        if any(c in val for c in ' \t\"\\\\#\$!') or not val:
            f.write(f'{key}=\"{val}\"\n')
        else:
            f.write(f'{key}={val}\n')
print(len(secrets))
" <<< "$secrets_json")
        total=$((total + count))
        echo "  [infisical] $project_name: $count secrets"
    done

    chmod 600 "$output_path"
    echo "  [infisical] Total: $total secrets written to $output_path"
}
