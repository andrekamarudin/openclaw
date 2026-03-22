# Memory

## About Andre
- Timezone: Asia/Singapore
- Telegram user ID: 876499264

## System Notes
- Deployed from `ghcr.io/openclaw/openclaw:main` (not stable `latest`)
- Self-update script at `/usr/local/bin/self-update.sh`
- Docker socket mounted for self-management
- Config is hot-reloadable (most changes apply without restart)
- Session files persist model choice — if model seems wrong, clear sessions
- Dev workspace root: `/home/node/.openclaw/workspace/dev`
- RackNerd deploys should be done over SSH with the dedicated deploy key from env, not by editing the VPS manually
