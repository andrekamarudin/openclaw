# Technical How

This file is the canonical explanation of how Andre's OpenClaw and adjacent self-hosted stacks are meant to be changed, deployed, and kept free of server drift.

Future agents should read this file before touching deployment scripts, VPS-managed config, or any repo that participates in these stacks.

## Core Idea

The operating model is:

1. GitHub repos hold the intended code and infra state.
2. Local working copies are where edits happen.
3. Infisical holds secrets.
4. SSH is used to trigger pulls, deploy scripts, health checks, and log inspection on the VPS.
5. The VPS is a runtime target, not the place where normal authoring happens.

In short: GitHub defines desired state, deploy scripts apply desired state.

## Current Repo Responsibilities

| Repo | Responsibility |
|------|----------------|
| `openclaw/` | OpenClaw infra workspace, compatibility assets, Contabo bootstrap scripts, canonical OpenClaw docs |
| `openwebui/` | Open WebUI compose, runtime helper, deploy/update scripts |
| `vikunja_wrapper/` | Wrapper app, wrapper infra, Postiz stack, RackNerd Caddy |
| `vikunja/` | Core Vikunja source for custom builds |
| `karakeep/` | Karakeep wrapper plus compose |
| `fishnet/` | Fishnet email-to-RSS stack |
| `code_anywhere/` | CodeAnywhere web UI, ChatKit endpoint, Telegram bot |
| `homarr/`, `infisical_app/`, `uptime_kuma/` | Compose-only Contabo services |
| `monitoring/` | Netdata and Dozzle across Contabo, RackNerd, and GreenCloud |
| `mcp/` | Repo MCP and Ops MCP |
| `nextcloud/`, `immich/` | GreenCloud stacks |
| `n8n/` | Hostinger n8n stack |
| `infra/` | Shared Caddy config, Infisical helpers, workspace-wide infra docs |

## Current VPS Topology

### Contabo

- IP: `46.250.234.28`
- Edge proxy: standalone Caddy at `/opt/caddy`
- Shared Docker network for proxied services: `caddy-net`

Main live paths:

- `/opt/src/openclaw`
- `/opt/src/openwebui`
- `/opt/src/vikunja_wrapper`
- `/opt/src/vikunja`
- `/opt/src/karakeep`
- `/opt/src/fishnet`
- `/opt/src/code_anywhere`
- `/opt/src/mcp`
- `/opt/src/self_hosting/infra`
- `/opt/openclaw`
- `/opt/openwebui`
- `/opt/vikunja`
- `/opt/karakeep`
- `/opt/fishnet`
- `/opt/code_anywhere`
- `/opt/mcp`
- `/root/.openclaw`

Main services:

- OpenClaw
- Open WebUI
- Vikunja plus wrapper
- Karakeep
- Infisical
- Homarr
- Uptime Kuma
- Fishnet
- Repo MCP and Ops MCP
- CodeAnywhere
- Contabo monitoring

### RackNerd

- IP: `23.226.133.245`
- Edge proxy: standalone Caddy at `/opt/caddy`
- Primary workloads: Postiz, Dozzle, Netdata

Main live paths:

- `/opt/src/vikunja_wrapper`
- `/opt/src/monitoring`
- `/opt/postiz`
- `/opt/monitoring`

### GreenCloud

- IP: `167.253.159.196`
- Edge proxy: Caddy inside the Nextcloud compose stack
- Primary workloads: Nextcloud, Immich, Dozzle, Netdata

Main live paths:

- `/opt/src/nextcloud`
- `/opt/src/immich`
- `/opt/src/monitoring`
- `/opt/nextcloud`
- `/opt/immich`
- `/opt/monitoring`
- `/mnt/storage`

### Hostinger

- IP: `31.97.71.85`
- Edge proxy: Caddy inside the n8n compose stack
- Primary workload: n8n

Main live paths:

- `/opt/src/n8n`
- `/opt/n8n`

## Path Conventions

- `/opt/src/<name>` holds the git-managed source checkout.
- `/opt/<name>/` holds live runtime files such as compose files, Caddyfiles, and env files.
- `/opt/config/` holds shared runtime helpers such as the Infisical agent env and fetch helper.
- Standalone Caddy hosts also keep `/opt/caddy/` for the edge proxy stack.

## Source Of Truth Rules

1. Do not treat SSH sessions as a normal editing environment.
2. Do not hand-edit repo-managed files on the VPS unless it is an emergency.
3. Make code and infra changes in the relevant local repo first.
4. Commit and push those changes to GitHub.
5. Use SSH only after the canonical branch contains the desired state.
6. If an emergency VPS edit is unavoidable, backport it into Git immediately and redeploy from source.

Repo-managed means things such as:

- compose files
- Caddy config
- deploy scripts
- config templates
- wrapper or OpenClaw source code
- workspace files and docs

Secrets and runtime-only state are the exception. They intentionally live outside Git, for example:

- local `.env` files that are not meant to be committed
- `/opt/<service>/.env` when populated by Infisical or manual bootstrap
- `/root/.openclaw/credentials/`
- container volumes and runtime-generated files

## How SSH Is Supposed To Be Used

Normal SSH uses:

- run deploy scripts
- pull the latest commits on the VPS
- inspect container status
- inspect logs
- run health checks
- restart services after config or image changes

SSH should usually not be used for:

- editing checked-in source files directly on the server
- editing repo-managed reverse-proxy or compose files by hand
- making a quick server-only fix and leaving Git behind

## Repo-Specific Deployment Notes

### OpenClaw

Expected workflow:

1. Edit locally in `openclaw/`.
2. Push to GitHub.
3. Trigger deploy with the local PowerShell helper or by running the VPS script.
4. Let `/opt/src/openclaw/openclaw-infra/scripts/deploy-openclaw.sh` or `deploy-build-openclaw.sh` pull, sync, and restart the stack.

Use `deploy-build-openclaw.sh` only when production must build from source instead of using the published image.

### Open WebUI

Expected workflow:

1. Edit locally in `openwebui/`.
2. Push to GitHub.
3. Run `/opt/src/openwebui/scripts/deploy-openwebui.sh` on Contabo, or let GitHub Actions do it.
4. Let the deploy script copy the compose file into `/opt/openwebui`, fetch secrets, restart the container, and re-apply database-backed runtime settings.

Open WebUI is routed by the standalone Contabo Caddy stack, not by host nginx.

### Vikunja Wrapper And Core

Expected workflow:

1. Edit wrapper changes in `vikunja_wrapper/` and core changes in `vikunja/`.
2. Use isolated worktrees where the repo requires them.
3. Push the finished change to GitHub.
4. Run `/opt/src/vikunja_wrapper/infra_assets/scripts/deploy-wrapper.sh` for wrapper-only changes.
5. Use `/opt/src/vikunja_wrapper/infra_assets/scripts/deploy-build-vikunja.sh` when a custom Vikunja core build is required.

The live Contabo stack sits at `/opt/vikunja` and is routed by standalone Contabo Caddy.

### Monitoring

Monitoring is per-host. Use the same repo on all three hosts, but pass the matching `INFISICAL_PROJECT` value when deploying.

### Fishnet

Fishnet is manual today. Use `/opt/src/fishnet/scripts/deploy.sh` on Contabo.

## Conflict-Free Deployment Pattern

To avoid collisions between local work, multiple agents, and server state:

1. Make changes in a local repo, not in a live checkout.
2. Use one isolated worktree per task where the repo requires it.
3. Push the reviewed result to the repo's default branch.
4. Use SSH only after the canonical branch contains the desired state.
5. Let the VPS fast-forward or pull that branch and run the deployment script.

This avoids common failure modes such as:

- local work diverging from what was hotfixed on the server
- multiple agents editing the same checkout concurrently
- live config no longer matching what the repo claims is deployed

## Short Version

The intended system is not “SSH into the box and tweak it until it works.”

It is:

1. local repo change
2. GitHub push
3. VPS pull via SSH or GitHub Actions
4. scripted deploy
5. health check

That is the mechanism that keeps OpenClaw and the rest of the self-hosting stack reproducible and understandable later.