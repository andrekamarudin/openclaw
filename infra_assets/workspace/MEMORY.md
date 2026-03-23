# Memory

## About Andre
- Timezone: Asia/Singapore
- Telegram user ID: 876499264

## System Notes
- Deployed from `ghcr.io/openclaw/openclaw:main` (not stable `latest`)
- Self-update script at `/usr/local/bin/self-update.sh`
- Docker socket mounted for self-management
- VPS root filesystem is mounted inside the container at `/hostfs`
- Config is hot-reloadable (most changes apply without restart)
- Session files persist model choice — if model seems wrong, clear sessions
- Dev workspace root: `/home/node/.openclaw/workspace/dev`
- Local workflow skill lives at `/home/node/.openclaw/workspace/skills/vikunja-dev`
- Infrastructure overview skill at `/home/node/.openclaw/workspace/skills/infra-overview` — covers all 3 VPSes, services, SSH details
- RackNerd deploys should be done over SSH with the dedicated deploy key from env, not by editing the VPS manually
- GreenCloud VPS (167.253.159.196) reuses the same SSH key as RackNerd — run `setup-greencloud-ssh.sh` to set up known_hosts
- Three VPSes: Contabo (this box, 46.250.234.28), RackNerd (23.226.133.245), GreenCloud (167.253.159.196)
