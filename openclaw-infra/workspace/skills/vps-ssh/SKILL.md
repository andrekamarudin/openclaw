---
name: vps-ssh
description: Use when you need SSH access to any of Andre's four VPS servers (Contabo, RackNerd, GreenCloud, Hostinger/n8n) to inspect containers, logs, or run commands. Covers setup scripts and SSH patterns for each host.
---

# VPS SSH Access

Andre has four VPS servers. This skill documents how to reach each one from inside the OpenClaw container.

## Limitations (inside OpenClaw container)

- `/hostfs` may not be accessible from exec context (bind mount absent or sandboxed)
- `docker` CLI is not in PATH — use `curl --unix-socket /var/run/docker.sock` for container ops
- SSH to the Contabo host itself (127.0.0.1) is not available without a separate key

## Contabo (this box)

You're already running on Contabo. For container-level operations use the Docker socket:

```bash
# List running containers
curl -s --unix-socket /var/run/docker.sock "http://localhost/containers/json" | jq '[.[] | {Name: .Names[0], Status: .Status}]'

# Get container logs (last 50 lines)
curl -s --unix-socket /var/run/docker.sock "http://localhost/containers/<name>/logs?tail=50&stdout=1&stderr=1"

# Restart a container
curl --unix-socket /var/run/docker.sock -X POST "http://localhost/containers/<name>/restart"
```

## RackNerd (Postiz — 23.226.133.245)

| Env var | Default |
|---------|---------|
| `RACKNERD_SSH_HOST` | 23.226.133.245 |
| `RACKNERD_SSH_PORT` | 22 |
| `RACKNERD_SSH_USER` | root |
| `RACKNERD_DEPLOY_KEY_B64` | (secret — base64 ed25519 key) |

```bash
# Step 1: decode key and scan host
KEY=$(/home/node/.openclaw/workspace/bin/setup-racknerd-ssh.sh)
KNOWN=/home/node/.openclaw/workspace/dev/.ssh/known_hosts

# Step 2: run a command
ssh -i "$KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes \
    -o UserKnownHostsFile="$KNOWN" \
    -p "${RACKNERD_SSH_PORT:-22}" \
    "${RACKNERD_SSH_USER:-root}@${RACKNERD_SSH_HOST}" \
    "docker ps --format 'table {{.Names}}\t{{.Status}}'"
```

## GreenCloud (Nextcloud + Immich — 167.253.159.196)

| Env var | Default |
|---------|---------|
| `GREENCLOUD_SSH_HOST` | 167.253.159.196 |
| `GREENCLOUD_SSH_PORT` | 22 |
| `GREENCLOUD_SSH_USER` | root |

Reuses the same key as RackNerd — `setup-racknerd-ssh.sh` runs automatically if the key is missing.

```bash
KEY=$(/home/node/.openclaw/workspace/bin/setup-greencloud-ssh.sh)
KNOWN=/home/node/.openclaw/workspace/dev/.ssh/known_hosts

ssh -i "$KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes \
    -o UserKnownHostsFile="$KNOWN" \
    -p "${GREENCLOUD_SSH_PORT:-22}" \
    "${GREENCLOUD_SSH_USER:-root}@${GREENCLOUD_SSH_HOST}" \
    "docker ps --format 'table {{.Names}}\t{{.Status}}'"
```

## Hostinger / n8n (n8n — 31.97.71.85)

| Env var | Default |
|---------|---------|
| `N8N_SSH_HOST` | 31.97.71.85 |
| `N8N_SSH_PORT` | 22 |
| `N8N_SSH_USER` | root |

Reuses the same key as RackNerd.

```bash
KEY=$(/home/node/.openclaw/workspace/bin/setup-n8n-ssh.sh)
KNOWN=/home/node/.openclaw/workspace/dev/.ssh/known_hosts

ssh -i "$KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes \
    -o UserKnownHostsFile="$KNOWN" \
    -p "${N8N_SSH_PORT:-22}" \
    "${N8N_SSH_USER:-root}@${N8N_SSH_HOST}" \
    "docker ps --format 'table {{.Names}}\t{{.Status}}'"
```

## Helper Script Reference

| Script | Purpose |
|--------|---------|
| `setup-racknerd-ssh.sh` | Decodes `RACKNERD_DEPLOY_KEY_B64`, scans RackNerd host; echoes key path |
| `setup-greencloud-ssh.sh` | Scans GreenCloud host key (reuses racknerd key); echoes key path |
| `setup-n8n-ssh.sh` | Scans n8n/Hostinger host key (reuses racknerd key); echoes key path |

All SSH keys and known_hosts land in: `/home/node/.openclaw/workspace/dev/.ssh/`
