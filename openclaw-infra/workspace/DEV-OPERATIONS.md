# OpenClaw Dev Operations

This workspace is set up so OpenClaw can:

- read GitHub issues through the GitHub API when `GITHUB_TOKEN` is present
- clone and update repos under `/home/node/.openclaw/workspace/dev`
- create isolated worktrees for concurrent development
- deploy to the RackNerd Vikunja host through repo-managed SSH deploy scripts
- install or update workspace skills through ClawHub without mixing them into the repo itself

## Core scripts

- `bin/dev-doctor.sh` — check what credentials and tools are ready
- `bin/bootstrap-dev-repos.sh` — clone/update the main repo checkouts
- `bin/create-worktree.sh <repo> <branch>` — create an isolated worktree
- `bin/github-issue.sh <owner/repo> <issue-number>` — fetch a GitHub issue as JSON
- `bin/deploy-racknerd.sh <wrapper|fast|core-build>` — run the RackNerd deploy scripts over SSH
- `bin/clawhub.sh <args...>` — run ClawHub with workspace-local defaults

## Local skills

- Workspace-local skills live in `/home/node/.openclaw/workspace/skills`
- The `vikunja-dev` skill wraps the repo bootstrap, worktree, GitHub issue, and RackNerd deploy workflow
- ClawHub installs also land in the workspace skills directory on the next session when run with `bin/clawhub.sh`

## Expected env vars

- `GITHUB_TOKEN` for private GitHub repo access and GitHub API access
- `GITHUB_VIKUNJA_CORE_REPO`, `GITHUB_VIKUNJA_CORE_PUSH_REPO`, `GITHUB_VIKUNJA_WRAPPER_REPO`
- `RACKNERD_SSH_HOST`, `RACKNERD_SSH_USER`, `RACKNERD_SSH_PORT`
- `RACKNERD_DEPLOY_KEY_B64` for the RackNerd deploy key

## Notes

- `go-vikunja/vikunja` is public and can be cloned without a token, but pushing requires a fork or direct push access.
- `andrekamarudin/vikunja_wrapper` is assumed private; cloning and issue access require `GITHUB_TOKEN`.
- Repo AGENTS instructions still apply inside the cloned repos.
- OpenClaw itself runs with sandbox mode off. The full VPS filesystem is mounted at `/hostfs` for host-level inspection and edits.