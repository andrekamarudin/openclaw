# AGENTS.md

Before making changes in this repo or in the related Vikunja and OpenClaw deployment repos, read `technical_how.md`.

`technical_how.md` is the canonical explanation of:

- which repo owns which part of the system
- how SSH is used against the VPS
- why GitHub is the source of truth for deployable code and infra
- how to avoid server drift and conflict-prone direct edits

When changing deployment scripts, infra assets, or docs that affect this workflow, keep `technical_how.md` updated in the same change.