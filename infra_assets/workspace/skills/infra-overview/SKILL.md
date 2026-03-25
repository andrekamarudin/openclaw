---
name: infra-overview
description: Use when answering questions about Andre's self-hosted infrastructure, services, repos, VPS servers, or when you need to SSH into any VPS to inspect logs, status, or configuration. Covers all four VPSes (Contabo, RackNerd, GreenCloud, Hostinger) and all hosted services.
---

# Infrastructure Overview

Andre runs self-hosted services across four VPS providers. This skill gives you the full map so you can answer questions and inspect any server.

## VPS Inventory

### 1. Contabo VPS (this box — OpenClaw lives here)

| Item | Value |
|------|-------|
| IP | `46.250.234.28` |
| SSH | Already local — you're running on this box |
| OS | Ubuntu 24.04 LTS |
| RAM | 12 GB |
| Reverse proxy | nginx + certbot (host-level, not containerized) |
| Compose dir | `/opt/openclaw/` |
| Repo checkout | `/hostfs/opt/src/my_openclaw` |
| .env (secrets) | `/opt/openclaw/.env` (from inside container: `/hostfs/opt/openclaw/.env`) |
| GitHub repo | `andrekamarudin/my_openclaw` (private, `master` branch) |

**Services on Contabo:**

| Service | Container | Internal Port | URL |
|---------|-----------|---------------|-----|
| OpenClaw Gateway | `openclaw-gateway` | :18789, :18790 | `https://openclaw.bytesizeprotip.com` |
| OpenClaw CLI | `openclaw-cli` | (shares gateway network) | — |
| Open WebUI | `open-webui` | 127.0.0.1:3000 → 8080 | `https://openwebui.bytesizeprotip.com` |
| Homarr | `homarr` | 127.0.0.1:7575 | `https://home.bytesizeprotip.com` |
| Uptime Kuma | `uptime-kuma` | 127.0.0.1:3001 | `https://status.bytesizeprotip.com` |

**Inspect commands (run locally, no SSH needed):**
```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker logs <container> --tail 50
cat /hostfs/opt/openclaw/docker-compose.yml
cat /hostfs/etc/nginx/sites-enabled/
systemctl status nginx        # via hostfs: nsenter or docker exec on host
curl -sf http://127.0.0.1:18789/healthz
curl -sf http://127.0.0.1:3000/health
curl -sf http://127.0.0.1:7575
curl -sf http://127.0.0.1:3001
```

---

### 2. RackNerd VPS (Vikunja — task management)

| Item | Value |
|------|-------|
| IP | Env var `RACKNERD_SSH_HOST` (currently `23.226.133.245`) |
| SSH | `ssh -i <key> -p ${RACKNERD_SSH_PORT:-22} ${RACKNERD_SSH_USER:-root}@${RACKNERD_SSH_HOST}` |
| SSH setup | Run `/home/node/.openclaw/workspace/bin/setup-racknerd-ssh.sh` first (writes key from `RACKNERD_DEPLOY_KEY_B64`) |
| OS | Ubuntu 22.04 LTS |
| RAM | 2 GB |
| Reverse proxy | Caddy (containerized, auto HTTPS) |
| Compose dir | `/opt/vikunja/` |
| Repo checkouts | `/opt/src/vikunja` (core), `/opt/src/vikunja_wrapper` (wrapper) |
| GitHub repos | `go-vikunja/vikunja` (public, `main`), `andrekamarudin/vikunja_wrapper` (private, `master`) |

**Services on RackNerd:**

| Service | Container | Internal Port | URL |
|---------|-----------|---------------|-----|
| Vikunja (core) | `vikunja` | :3456 | `https://tasks.bytesizeprotip.com` |
| Vikunja Wrapper | `llm-chat` | :3000 | `https://tasks.bytesizeprotip.com/llm` |
| Postiz | `postiz` | :5000 | `https://postiz.bytesizeprotip.com` |
| Caddy | `caddy` | :80, :443 | (reverse proxy) |

**SSH helper (preferred):**
```bash
/home/node/.openclaw/workspace/bin/setup-racknerd-ssh.sh
# Returns the key path; then:
KEY=$(/home/node/.openclaw/workspace/bin/setup-racknerd-ssh.sh)
KNOWN=/home/node/.openclaw/workspace/dev/.ssh/known_hosts
ssh -i "$KEY" -o IdentitiesOnly=yes -o StrictHostKeyChecking=yes \
    -o UserKnownHostsFile="$KNOWN" \
    -p "${RACKNERD_SSH_PORT:-22}" \
    "${RACKNERD_SSH_USER:-root}@${RACKNERD_SSH_HOST}" \
    "<command>"
```

**Common inspect commands (via SSH):**
```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker logs vikunja --tail 50
docker logs vikunja-wrapper --tail 50
cat /opt/vikunja/docker-compose.yml
cat /opt/vikunja/.env
curl -sf http://127.0.0.1:3456/api/v1/info
curl -sf http://127.0.0.1:8080/health
```

**Deploy commands (from this box):**
```bash
/home/node/.openclaw/workspace/bin/deploy-racknerd.sh wrapper    # redeploy wrapper
/home/node/.openclaw/workspace/bin/deploy-racknerd.sh fast        # fast deploy (no rebuild)
/home/node/.openclaw/workspace/bin/deploy-racknerd.sh core-build  # rebuild vikunja core
```

---

### 3. GreenCloud VPS (Nextcloud + Immich — storage services)

| Item | Value |
|------|-------|
| IP | Env var `GREENCLOUD_SSH_HOST` (currently `167.253.159.196`) |
| SSH | `ssh -i <key> -p ${GREENCLOUD_SSH_PORT:-22} ${GREENCLOUD_SSH_USER:-root}@${GREENCLOUD_SSH_HOST}` |
| SSH setup | Run `/home/node/.openclaw/workspace/bin/setup-greencloud-ssh.sh` first (reuses the same key as RackNerd) |
| OS | Ubuntu 22.04 LTS |
| RAM | 6 GB |
| CPU | 4 cores |
| Disks | 60 GB NVMe (OS) + 2 TB HDD (`/mnt/storage`) |
| Reverse proxy | Caddy (containerized, auto HTTPS) |
| Compose dir | `/opt/nextcloud/` |
| Repo checkout | `/opt/src/greencloud` |
| GitHub repo | `andrekamarudin/greencloud_vps` (private, `master`) |

**Services on GreenCloud:**

| Service | Container | Internal Port | URL |
|---------|-----------|---------------|-----|
| Nextcloud | `nextcloud` | :80 | `https://nextcloud.bytesizeprotip.com` |
| Immich | `immich-server` | :2283 | `https://immich.bytesizeprotip.com` |
| Nextcloud DB | `nextcloud-db` | (Postgres 16) | — |
| Nextcloud Redis | `nextcloud-redis` | (Redis 7) | — |
| Immich DB | `immich-db` | (Postgres 16 + pgvecto) | — |
| Immich ML | `immich-ml` | (face recognition) | — |
| Immich Redis | `immich-redis` | (Redis 7) | — |
| Caddy | `caddy` | :80, :443 | (reverse proxy) |

**Common inspect commands (via SSH):**
```bash
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'
docker logs nextcloud --tail 50
docker logs immich-server --tail 50
docker exec nextcloud php occ status
cat /opt/nextcloud/docker-compose.yml
df -h /mnt/storage
ufw status verbose
fail2ban-client status sshd
fail2ban-client status nextcloud
```

---

---

### 4. Hostinger VPS (n8n automation)

| Item | Value |
|------|-------|
| IP | `31.97.71.85` |
| SSH | `ssh hostinger` (uses `~/.ssh/config` alias) |
| Hostname | `srv935644.hstgr.cloud` |

**Services on Hostinger:**

| Service | URL |
|---------|-----|
| n8n | `https://n8n.srv935644.hstgr.cloud` |

**Managed via:** Hostinger API + direct SSH. Local management repo: `hostinger/` (GitHub: `hk_hostinger`).

---

## DNS Records (all under `bytesizeprotip.com`)

| Subdomain | A Record | VPS |
|-----------|----------|-----|
| `openclaw.bytesizeprotip.com` | `46.250.234.28` | Contabo |
| `openwebui.bytesizeprotip.com` | `46.250.234.28` | Contabo |
| `home.bytesizeprotip.com` | `46.250.234.28` | Contabo |
| `status.bytesizeprotip.com` | `46.250.234.28` | Contabo |
| `tasks.bytesizeprotip.com` | `23.226.133.245` | RackNerd |
| `postiz.bytesizeprotip.com` | `23.226.133.245` | RackNerd |
| `nextcloud.bytesizeprotip.com` | `167.253.159.196` | GreenCloud |
| `immich.bytesizeprotip.com` | `167.253.159.196` | GreenCloud |

## GitHub Repos

| Repo | Owner | Branch | Manages |
|------|-------|--------|---------|
| `my_openclaw` | `andrekamarudin` (private) | `master` | Contabo VPS infra, OpenClaw config, workspace |
| `vikunja_wrapper` | `andrekamarudin` (private) | `master` | Vikunja wrapper API, RackNerd deploy scripts |
| `vikunja` | `go-vikunja` (public) | `main` | Vikunja core (upstream fork) |
| `greencloud_vps` | `andrekamarudin` (private) | `master` | GreenCloud VPS infra, Nextcloud + Immich deploy (local folder: `greencloud/`) |
| `hk_hostinger` | `andrekamarudin` (private) | `master` | Hostinger VPS management, n8n (local folder: `hostinger/`) |

## Source of Truth

- **Code and infra config**: GitHub repos
- **Non-secret config**: committed `.env` in each repo (URLs, ports, feature flags)
- **Secrets**: Infisical at `https://knives.bytesizeprotip.com` — fetched by deploy scripts at runtime
- **Deploy flow**: Push to GitHub → SSH to VPS → run deploy script → script does git pull + docker compose up
- **Do NOT** hand-edit repo-managed files directly on VPSes
- For the full operating model, read `technical_how.md` at the `self_hosting` workspace root
