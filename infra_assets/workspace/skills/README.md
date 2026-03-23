# Workspace Skills

Skills in this directory are loaded by OpenClaw as workspace-local skills on the next session.

- `vikunja-dev` is the local skill for GitHub issue triage, repo bootstrap, concurrent worktrees, and RackNerd deploys.
- `infra-overview` is the infrastructure reference skill covering all 3 VPSes, services, SSH access, repos, and DNS.
- `telegram-settings` is the self-service skill for inspecting and changing Telegram channel config (group policy, DM policy, allowed users) and restarting the gateway to apply changes.
- ClawHub installs should also land here when run through `bin/clawhub.sh`.
- If you add or update skills here, start a new session so OpenClaw reloads them.