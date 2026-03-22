# OpenClaw Dev Operations

This workspace is set up so OpenClaw can:

- read GitHub issues through the GitHub API when `GITHUB_TOKEN` is present
- clone and update repos under `/home/node/.openclaw/workspace/dev`
- create isolated worktrees for concurrent development
- deploy to the RackNerd Vikunja host through repo-managed SSH deploy scripts

## Core scripts

- `bin/dev-doctor.sh` — check what credentials and tools are ready
- `bin/bootstrap-dev-repos.sh` — clone/update the main repo checkouts
- `bin/create-worktree.sh <repo> <branch>` — create an isolated worktree
- `bin/github-issue.sh <owner/repo> <issue-number>` — fetch a GitHub issue as JSON
- `bin/deploy-racknerd.sh <wrapper|fast|core-build>` — run the RackNerd deploy scripts over SSH

## Expected env vars

- `GITHUB_TOKEN` for private GitHub repo access and GitHub API access
- `GITHUB_VIKUNJA_CORE_REPO`, `GITHUB_VIKUNJA_CORE_PUSH_REPO`, `GITHUB_VIKUNJA_WRAPPER_REPO`
- `RACKNERD_SSH_HOST`, `RACKNERD_SSH_USER`, `RACKNERD_SSH_PORT`
- `RACKNERD_DEPLOY_KEY_B64` for the RackNerd deploy key

## Notes

- `go-vikunja/vikunja` is public and can be cloned without a token, but pushing requires a fork or direct push access.
- `andrekamarudin/vikunja_wrapper` is assumed private; cloning and issue access require `GITHUB_TOKEN`.
- Repo AGENTS instructions still apply inside the cloned repos.