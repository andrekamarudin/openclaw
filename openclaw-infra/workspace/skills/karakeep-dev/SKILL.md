---
name: karakeep-dev
description: Use the local Karakeep development workflow for wrapper development, deploy, and issue management. Use when working on karakeep_wrapper or Karakeep infra from this OpenClaw workspace.
---

# Karakeep Dev Workflow

Use this skill when the task is about `karakeep_wrapper` development or Karakeep infrastructure from the Contabo OpenClaw box.

## Paths

- Wrapper source: `/opt/src/karakeep_wrapper`
- Worktrees: `/home/node/.openclaw/workspace/dev/worktrees`
- Helper scripts: `/home/node/.openclaw/workspace/bin`
- Infra configs: `/opt/src/my_openclaw/infra_assets`
- Compose file: `/opt/src/my_openclaw/infra_assets/compose/docker-compose.karakeep.yml`
- Deploy script: `/opt/src/my_openclaw/infra_assets/scripts/deploy-karakeep.sh`
- Karakeep stack: `/opt/karakeep`
- Wrapper env: `/opt/config/karakeep_wrapper.env`
- Karakeep env: `/opt/karakeep/.env`

## First steps

1. Run `/home/node/.openclaw/workspace/bin/dev-doctor.sh`.
2. Read `/opt/src/karakeep_wrapper/README.md` before changing code.

## GitHub issues

- Wrapper issues require `GITHUB_TOKEN` for the private repo:
  `/home/node/.openclaw/workspace/bin/github-issue.sh andrekamarudin/karakeep_wrapper <issue-number>`
- Feedback issues go to the repo specified in `GITHUB_FEEDBACK_REPO`

## Worktrees

- Create worktree:
  `/home/node/.openclaw/workspace/bin/create-worktree.sh karakeep_wrapper <branch>`
- All `karakeep_wrapper` work must happen in an isolated worktree and integrate back to `master`.
- After completing work in a worktree, sync changes to the main checkout, resolve any conflicts, push to `origin master`, and delete the worktree.

## Architecture

Karakeep runs as three containers plus a wrapper:

| Container | Port | Purpose |
|-----------|------|---------|
| karakeep-web | 3458 (→3000) | Karakeep app (NextAuth) |
| karakeep-chrome | — | Browser worker for bookmarks |
| karakeep-meilisearch | — | Full-text search |
| karakeep-wrapper | 3459 (→3000) | FastAPI paid-access gating |

The wrapper provides:
- **Auth**: Validates Karakeep API keys via `/api/v1/users/whoami`
- **Whop gating**: Checks subscription tier (plus/unlimited)
- **/api/feedback**: Creates LLM-enriched GitHub issues
- **/api/chat**: Bookmark management assistant for paid users
- **/api/subscription**: Subscription status check

## Wrapper source structure

```
karakeep_wrapper/
  auth.py        — Karakeep API key validation
  config.py      — Pydantic settings (env-based)
  feedback.py    — GitHub issue creation + LLM enrichment
  main.py        — FastAPI routes
  whop.py        — Whop subscription checker
  Dockerfile     — Python 3.12-slim, uvicorn on port 3000
  requirements.txt
  static/        — Frontend assets (feedback, LLM chat UI)
```

## Deploy

```bash
# From VPS:
bash /opt/src/my_openclaw/infra_assets/scripts/deploy-karakeep.sh
```

The deploy script:
1. Copies compose file to `/opt/karakeep/`
2. Seeds env files if missing
3. Fetches secrets from Infisical (per-project vault)
4. Pulls images and builds wrapper
5. Brings up the stack

## Secrets (Infisical)

Karakeep secrets are in the `contabo-karakeep` Infisical project (ID: `70c9a89e-52bc-4dee-9a95-3c74915e0a5f`):
- KARAKEEP_VERSION, NEXTAUTH_SECRET, MEILI_MASTER_KEY, NEXTAUTH_URL
- OPENAI_API_KEY (for AI tagging)
- INFERENCE_TEXT_MODEL, INFERENCE_IMAGE_MODEL
- INFERENCE_ENABLE_AUTO_TAGGING, INFERENCE_ENABLE_AUTO_SUMMARIZATION

**Do NOT use god-keys.** god-keys is the master vault for local dev only. VPS agents must fetch from per-project vaults only.

Wrapper secrets are in `/opt/config/karakeep_wrapper.env`:
- KARAKEEP_API_URL, LLM_API_KEY, LLM_MODEL, LLM_BASE_URL
- WHOP_API_KEY, WHOP_PRODUCT_ID
- GITHUB_FEEDBACK_TOKEN, GITHUB_FEEDBACK_REPO

## AGPL-3.0 compliance

Karakeep core is AGPL-3.0. The wrapper is a **separate application** that communicates via Karakeep's REST API only. Never modify Karakeep core source — all customizations must stay in the wrapper.

## Nginx

- Domain: `karakeep.bytesizeprotip.com`
  - `/` → port 3458 (Karakeep UI)
  - `/wrapper/*` → port 3459 (wrapper API, prefix stripped)
- Wrapper API accessible at `https://karakeep.bytesizeprotip.com/wrapper/api/chat`, etc.

## Notes

- `GITHUB_TOKEN` is required for the private `karakeep_wrapper` repo.
- Karakeep uses NextAuth — users create API keys in Settings → API Keys.
- The wrapper validates tokens against Karakeep's `/api/v1/users/whoami`.
- The VPS root filesystem is mounted at `/hostfs` if host-level inspection is required.
