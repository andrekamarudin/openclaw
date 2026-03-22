---
name: vikunja-dev
description: Use the local Vikunja development workflow for GitHub issue fetches, repo bootstrap, isolated worktrees, and RackNerd deploys. Use when working on go-vikunja/vikunja or andrekamarudin/vikunja_wrapper from this OpenClaw workspace.
---

# Vikunja Dev Workflow

Use this skill when the task is about `vikunja` or `vikunja_wrapper` development from the Contabo OpenClaw box.

## Paths

- Dev root: `/home/node/.openclaw/workspace/dev`
- Main checkouts: `/home/node/.openclaw/workspace/dev/main`
- Worktrees: `/home/node/.openclaw/workspace/dev/worktrees`
- Helper scripts: `/home/node/.openclaw/workspace/bin`

## First steps

1. Run `/home/node/.openclaw/workspace/bin/dev-doctor.sh`.
2. Run `/home/node/.openclaw/workspace/bin/bootstrap-dev-repos.sh`.
3. Read the checked-out repo `AGENTS.md` before changing code.

## GitHub issues

- Public issues: `/home/node/.openclaw/workspace/bin/github-issue.sh go-vikunja/vikunja <issue-number>`
- Private wrapper issues require `GITHUB_TOKEN`:
  `/home/node/.openclaw/workspace/bin/github-issue.sh andrekamarudin/vikunja_wrapper <issue-number>`

## Worktrees

- Generic helper:
  `/home/node/.openclaw/workspace/bin/create-worktree.sh <repo> <branch>`
- `vikunja_wrapper` work must happen in an isolated worktree and integrate back to `master`.
- `vikunja` work must follow its repo instructions. When the task is tied to a written plan, use `mage dev:prepare-worktree <name> <plan-path>` from the `vikunja` repo instead of the generic helper.

## Deploys

- Wrapper deploy: `/home/node/.openclaw/workspace/bin/deploy-racknerd.sh wrapper`
- Fast deploy: `/home/node/.openclaw/workspace/bin/deploy-racknerd.sh fast`
- Core rebuild deploy: `/home/node/.openclaw/workspace/bin/deploy-racknerd.sh core-build`

## ClawHub

- Search: `/home/node/.openclaw/workspace/bin/clawhub.sh search "query"`
- Install a skill into this workspace: `/home/node/.openclaw/workspace/bin/clawhub.sh install <slug>`
- Update installed skills: `/home/node/.openclaw/workspace/bin/clawhub.sh update --all`

## Notes

- `GITHUB_TOKEN` is required for the private `vikunja_wrapper` repo.
- `GITHUB_VIKUNJA_CORE_PUSH_REPO` is required if core changes need to be pushed to a fork instead of staying local.
- The VPS root filesystem is mounted at `/hostfs` if host-level inspection is required.