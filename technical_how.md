# Technical How

This file is the canonical explanation of how Andre's Vikunja and OpenClaw systems are meant to be changed, deployed, and kept free of server drift.

Future agents should read this file before touching deployment scripts, VPS-managed config, or any repo that participates in these stacks.

## Core Idea

The operating model is:

1. GitHub repos hold the intended code and infra state.
2. Local working copies are where edits happen.
3. SSH is used to trigger pulls, deploy scripts, health checks, and log inspection on the VPS.
4. The VPS is a runtime target, not the place where normal authoring happens.

In short: GitHub defines desired state, SSH applies desired state.

## Repo Responsibilities

### OpenClaw side

- `my_openclaw` is the source of truth for OpenClaw infra assets, deploy scripts, docs, and local secret-management workflow.
- Local `.env` in `my_openclaw` is the source of truth for OpenClaw secrets and Contabo SSH access details.
- `openclaw` is the app source repo used only when you need a source-build deployment instead of consuming the published image.

Inside `my_openclaw`, the canonical layout is now:

- `openclaw-infra/` - OpenClaw stack Compose files, config, workspace files, and OpenClaw deploy scripts
- `openwebui/` - Open WebUI nginx templates, deploy scripts, and Open WebUI docs
- `infra_assets/` - remaining shared assets and compatibility wrappers for services such as Homarr and Uptime Kuma

### Vikunja side

- `vikunja_wrapper` is the source of truth for the wrapper app, wrapper-specific infra assets, deploy scripts, and reverse-proxy wiring.
- `vikunja` is the upstream core source checkout. On the VPS, production normally runs the official Vikunja image even though a source checkout also exists.

## VPS Layout

There are two separate VPS hosts:

### OpenClaw VPS (12 GB RAM)

This is the multi-app host where OpenClaw runs and maintains other deployed apps (including Open WebUI). OpenClaw has Docker socket access and can deploy/manage sibling containers.

Important live paths:

- `/opt/src/my_openclaw` - checkout of the infra repo for OpenClaw
- `/opt/src/openclaw` - checkout of the OpenClaw app fork for source builds
- `/opt/openclaw` - live OpenClaw Compose stack directory (also hosts Open WebUI)
- `/etc/nginx/sites-available/*.conf` - host nginx virtual-host configs for public endpoints
- `/root/.openclaw` - live OpenClaw runtime config, sessions, workspace, and credentials

Containers on this VPS:

- `openclaw-gateway` — the AI assistant (ports 18789/18790)
- `openclaw-cli` — CLI companion (shares gateway network)
- `open-webui` — multi-user LLM chat UI (container port 8080, bound to localhost on the host)
- `nginx` — host reverse proxy providing HTTPS for Open WebUI and OpenClaw domains

### Vikunja VPS (2 GB RAM)

This is a separate, smaller VPS dedicated to Vikunja. OpenClaw on the other VPS maintains it remotely via SSH.

Important live paths:

- `/opt/src/vikunja_wrapper` - checkout of the wrapper repo
- `/opt/src/vikunja` - checkout of the core Vikunja repo
- `/opt/vikunja` - live Vikunja Compose stack directory
- `/opt/config/vikunja_wrapper.env` - wrapper runtime secrets kept out of git

### Path conventions

Both VPSes follow the same layout convention:

- `/opt/src/...` holds git-managed source checkouts.
- `/opt/<app>/` holds live runtime stack files (Compose, env, scripts).
- Runtime state directories (e.g. `/root/.openclaw`) hold app-specific config, sessions, and workspace data.

## Source Of Truth Rules

These rules are the main protection against conflicting deploys and server drift.

1. Do not treat SSH sessions as a normal editing environment.
2. Do not hand-edit repo-managed files on the VPS unless it is an emergency.
3. Make code and infra changes in the relevant local repo first.
4. Commit and push those changes to GitHub.
5. Use SSH to pull and deploy the already-pushed state on the VPS.
6. If an emergency VPS edit is unavoidable, backport it into Git immediately and redeploy from source of truth.

Repo-managed means things like:

- Compose files
- reverse-proxy config
- deploy scripts
- config templates
- wrapper source code
- OpenClaw infra assets

Secrets and runtime-only state are the exception. They intentionally live outside Git, for example:

- `my_openclaw/.env` locally
- `/opt/openclaw/.env` on the VPS
- `/opt/config/vikunja_wrapper.env` on the VPS
- `/root/.openclaw/credentials/`
- persisted sessions and runtime-generated files

## How SSH Is Supposed To Be Used

SSH is for controlled operations, not freehand configuration drift.

Normal SSH uses:

- run deploy scripts
- pull latest commits on the VPS
- inspect container status
- inspect logs
- copy the local secret `.env` to the VPS when needed
- run health checks
- restart services after a config or image change

SSH should usually not be used for:

- editing checked-in source files directly on the server
- editing repo-managed reverse-proxy or Compose files by hand
- making a quick server-only fix and leaving Git behind

## OpenClaw Deployment Model

The standard OpenClaw workflow is:

1. Edit `my_openclaw` locally.
2. Push to GitHub.
3. Use local PowerShell or SSH to trigger the deploy on the VPS.
4. The VPS updates from Git and recreates the relevant container state.

Primary repos and roles:

- `my_openclaw` owns infra assets, templates, docs, and deploy automation.
- `openclaw` only matters when you are building from your fork instead of pulling `ghcr.io/openclaw/openclaw:main`.

Normal image-based OpenClaw deploy path:

1. Update `my_openclaw` locally.
2. Push to GitHub.
3. Run `scripts/deploy-contabo-openclaw.ps1` locally or invoke the matching VPS deploy script over SSH.
4. On the VPS, `/opt/src/my_openclaw/openclaw-infra/scripts/deploy-openclaw.sh` pulls repo changes, applies repo-managed assets, updates the image if needed, and restarts the stack.

Source-build OpenClaw deploy path:

1. Update the `openclaw` fork locally.
2. Push to GitHub.
3. Run `/opt/src/my_openclaw/openclaw-infra/scripts/deploy-build-openclaw.sh` on the VPS.
4. The VPS uses `/opt/src/openclaw` as build input and redeploys from source.

Operational rule:

- For infra changes, change `my_openclaw`.
- For application code changes that require a custom build, change `openclaw`.
- Do not patch either directly inside `/opt/src/...` on the VPS as the primary workflow.

## Open WebUI Deployment Model

Open WebUI runs on the same Contabo VPS as OpenClaw, in a separate container published on localhost and fronted by the host nginx service for HTTPS.

- Image: `ghcr.io/open-webui/open-webui:main` (official, no Ollama)
- Reverse proxy: host nginx with certbot-managed TLS
- All infra is managed in `my_openclaw` (Compose, nginx templates, deploy scripts, env vars)
- Signup is disabled — admin creates accounts manually

Deploy scripts:

- Full deploy: `openwebui/scripts/deploy-openwebui.sh` (git pull → apply OpenClaw/Open WebUI assets → pull image → restart)
- Quick update: `openwebui/scripts/update-openwebui.sh` (pull image → restart only)
- Bootstrap: `scripts/deploy-contabo-openclaw.ps1` starts Open WebUI and configures nginx + TLS

The nginx templates under `openwebui/nginx/` are synced by `openclaw-infra/scripts/apply-openclaw-infra.sh`. Before a certificate exists, the HTTP-only template is deployed; after certbot issues a certificate, the HTTPS template becomes the repo-managed source of truth. The older `infra_assets/scripts/apply-infra-assets.sh` wrapper still exists for compatibility with shared-service callers.

## Vikunja Deployment Model

The Vikunja side is split between core and wrapper.

### Wrapper

The wrapper is source-built from the VPS checkout at `/opt/src/vikunja_wrapper`.

Expected workflow:

1. Edit locally in `vikunja_wrapper`.
2. Use an isolated git worktree for implementation because that repo explicitly requires it.
3. Push the finished change to GitHub `master`.
4. On the VPS, run `/opt/src/vikunja_wrapper/infra_assets/scripts/deploy-wrapper.sh`.
5. That script fast-forwards from GitHub, reapplies repo-managed infra assets, rebuilds `llm-chat`, and keeps Caddy aligned.

Important wrapper rule:

- If a new wrapper route or page is added, update `infra_assets/caddy/Caddyfile` in the same change so the reverse proxy matches the deployed app.

### Core Vikunja

The VPS also has a source checkout at `/opt/src/vikunja`, but production usually runs the official image rather than a custom source build.

Expected workflow:

1. Decide whether the change is a source-code change or just an image refresh.
2. For code work, make changes locally in a dedicated worktree for the `vikunja` repo and push to GitHub.
3. For production updates, use the repo-managed VPS helper such as `/opt/src/vikunja_wrapper/infra_assets/scripts/update-vikunja.sh`.
4. Let the server pull or refresh from the declared source rather than hand-editing the live stack.

## Conflict-Free Deployment Pattern

To avoid collisions between local work, multiple agents, and server state:

1. Make changes in a local repo, not in the shared live checkout.
2. For repos that require worktrees, use one isolated worktree per task.
3. Push the reviewed result to the repo's default branch or required integration branch.
4. Use SSH only after the canonical branch contains the desired state.
5. Let the VPS fast-forward or pull that branch and run the deployment script.

This avoids three common failure modes:

- local work diverging from what was hotfixed on the server
- multiple agents editing the same checkout concurrently
- live config no longer matching what the repo claims is deployed

## Direct-To-Server Paths

Some direct server-oriented paths still exist, for example a direct git remote push for `vikunja_wrapper` production.

Treat those as compatibility paths, not the preferred mental model.

For conflict-free operations, prefer:

1. local change
2. push to GitHub
3. SSH into the VPS only to pull and deploy

That keeps GitHub as the auditable integration point and reduces ambiguity about what is actually supposed to be running.

## Live-Edit Exceptions

Direct VPS edits are only acceptable when the alternative is downtime or broken access and there is no safe time to go through the full repo workflow first.

If that happens:

1. keep the edit minimal
2. document exactly what changed
3. port the same change back into the correct repo immediately
4. commit and push it
5. redeploy from the repo-managed path so the server returns to a clean, reproducible state

Emergency edits are not complete until the repo catches up.

## Practical Mental Model For Future Agents

When deciding where a change belongs, ask these questions in order:

1. Is this OpenClaw infra, docs, deploy automation, or config templating? Use `my_openclaw`.
2. Is this OpenClaw app source code for a custom source build? Use `openclaw`.
3. Is this wrapper app behavior, wrapper infra, or proxy wiring? Use `vikunja_wrapper`.
4. Is this core Vikunja source behavior? Use `vikunja`.
5. Is this only a live secret or runtime state value? Change the server-side secret or runtime location, not Git.

Then apply the deployment rule:

- change locally
- push to GitHub
- SSH to pull and deploy
- avoid server-only edits

## Short Version

The intended system is not "SSH into the box and tweak it until it works."

It is:

1. local repo change
2. GitHub push
3. VPS pull via SSH
4. scripted deploy
5. health check

That is the mechanism that keeps Vikunja and OpenClaw reproducible, conflict-free, and understandable later.