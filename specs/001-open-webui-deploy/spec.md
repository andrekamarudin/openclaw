# Feature Specification: Open WebUI Deployment

**Feature Branch**: `001-open-webui-deploy`
**Created**: 2026-03-23
**Status**: Draft
**Input**: User description: "Deploy Open WebUI on same VPS as OpenClaw in a separate Docker container, following the same GitHub-first deployment model"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Chat with LLMs via browser (Priority: P1)

Andre or a family member opens Open WebUI in a browser, selects a model (e.g. GPT-5.4-mini, Claude Sonnet), and has a multi-turn conversation. The conversation is persisted so it survives browser refreshes and container restarts.

**Why this priority**: The core value proposition. Without a working chat interface connected to at least one LLM provider, nothing else matters.

**Independent Test**: Can be fully tested by navigating to the Open WebUI URL, logging in, starting a conversation, refreshing the page, and confirming the conversation is still there.

**Acceptance Scenarios**:

1. **Given** Open WebUI is deployed and running, **When** Andre navigates to the access URL, **Then** the login page loads within 5 seconds
2. **Given** Andre is logged in and selects a model, **When** Andre sends a message, **Then** the model responds with streamed output
3. **Given** an active conversation exists, **When** Andre refreshes the browser, **Then** the conversation history is preserved

---

### User Story 2 - Deploy or update Open WebUI from Git (Priority: P1)

Andre pushes a change to the `openclaw` repo (infra assets, config template, or compose file), then triggers a deploy script over SSH or asks the OpenClaw agent to deploy. The VPS pulls the latest commit, applies the new configuration, and restarts only the Open WebUI container without affecting OpenClaw.

**Why this priority**: Equal to P1 because the deployment model is a hard requirement, not optional infrastructure. Without it, the service cannot be maintained conflict-free.

**Independent Test**: Can be tested by making a trivial config change, pushing to GitHub, running the deploy script, and confirming the container restarts with the updated config.

**Acceptance Scenarios**:

1. **Given** a change is pushed to `openclaw` on GitHub, **When** the deploy script runs on the VPS, **Then** Open WebUI is updated without affecting the OpenClaw container
2. **Given** OpenClaw is running, **When** the Open WebUI container is stopped or restarted, **Then** OpenClaw continues operating normally
3. **Given** the Open WebUI container is recreated, **When** Andre opens the UI, **Then** previous conversations and settings are still present

---

### User Story 3 - Use multiple LLM providers (Priority: P2)

Andre configures Open WebUI to use multiple LLM providers (OpenAI, Anthropic, OpenRouter, Groq) with the API keys already present on the VPS. Andre can switch between models within a single chat session.

**Why this priority**: Expands the utility of the deployment but the core chat experience works with even a single provider.

**Independent Test**: Can be tested by configuring two providers, starting a conversation with one model, switching to another model in the same or new conversation, and confirming both respond correctly.

**Acceptance Scenarios**:

1. **Given** multiple providers are configured, **When** Andre opens the model selector, **Then** models from all configured providers are listed
2. **Given** Andre is in a conversation, **When** Andre switches to a different model, **Then** the next response comes from the newly selected model

---

### User Story 4 - Family members use Open WebUI (Priority: P2)

Andre creates accounts for family members. Each family member logs in with their own credentials, has their own conversation history, and can select from the available models. Andre retains admin control over account creation and model access.

**Why this priority**: Extends the core value to the intended user base but is not needed for the initial single-user deployment to work.

**Independent Test**: Can be tested by creating a second user account, logging in as that user, starting a conversation, and confirming it is isolated from Andre's conversations.

**Acceptance Scenarios**:

1. **Given** Andre has admin access, **When** Andre creates a new user account, **Then** that user can log in and start conversations
2. **Given** two users are logged in, **When** each sends a message, **Then** their conversation histories are isolated from each other
3. **Given** a non-admin user is logged in, **When** they try to access admin settings, **Then** they are denied

---

### Edge Cases

- What happens when the VPS runs out of memory with OpenClaw + Open WebUI + future apps running simultaneously?
- What happens when an LLM API key is invalid or expired in the Open WebUI configuration?
- What happens when the Open WebUI container crashes — does it auto-restart without manual intervention?
- What happens when a deploy script is run but the GitHub repo has not changed — does it handle the no-op gracefully?
- What happens when Open WebUI and OpenClaw are configured with the same API key but different rate-limit budgets at a provider?
- What happens when a family member exceeds reasonable usage — is there any per-user rate limiting?
- What happens when registration is opened for paying customers — how is billing integrated?

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Open WebUI MUST run as a separate container on the OpenClaw VPS (12 GB RAM) alongside OpenClaw, with independent lifecycle (start, stop, restart, update). Vikunja runs on a separate 2 GB VPS and is not affected.
- **FR-002**: Open WebUI MUST persist conversations, user accounts, and settings across container restarts using a durable storage volume
- **FR-003**: The deployment MUST follow the same GitHub-first model as OpenClaw: changes committed to `openclaw`, pushed to GitHub, pulled on the VPS, and applied via a deploy script
- **FR-004**: The `openclaw` repo MUST contain all repo-managed assets for Open WebUI: the shared Compose service definition under `openclaw-infra/compose/` and the nginx/deploy assets under `openwebui/`
- **FR-005**: Secrets (API keys, admin credentials) MUST be stored outside of Git, in a VPS-side env file, consistent with the existing pattern
- **FR-006**: Open WebUI MUST connect to remote LLM providers (OpenAI, Anthropic, OpenRouter, Groq) using the API keys already available on the VPS — no local model inference (Ollama) is required for the initial deployment
- **FR-007**: Open WebUI MUST be accessible via a dedicated subdomain (e.g. `chat.yourdomain.com`) reverse-proxied through Caddy with automatic HTTPS, matching the existing Vikunja reverse-proxy pattern
- **FR-008**: The Open WebUI container MUST auto-restart after VPS reboots or unexpected crashes
- **FR-009**: The existing OpenClaw asset-apply flow (`openclaw-infra/scripts/apply-openclaw-infra.sh`, or a compatibility wrapper) MUST sync Open WebUI assets alongside OpenClaw assets during deployment
- **FR-010**: Open WebUI MUST support multiple users. Andre is the admin who creates accounts for family members. Public registration MUST be disabled; only admin-created accounts can access the service
- **FR-011**: The Open WebUI container MUST be capped at 2 GB memory (mem_limit) with 4 GB swap (memswap_limit) on the 12 GB VPS, leaving headroom for OpenClaw and future apps
- **FR-012**: The system MUST be designed so that future paid-customer access can be added without re-architecting (e.g. admin approval registration, per-user model access controls)

### Key Entities

- **Open WebUI Container**: The running service instance with its own lifecycle, ports, volumes, and resource limits, independent from OpenClaw and Vikunja
- **Open WebUI Data Volume**: Persistent storage for conversations, user accounts, model configurations, and uploaded files
- **Open WebUI Env File**: VPS-side secrets file (API keys, admin password) kept outside Git, similar to `/opt/openclaw/.env`
- **Deploy Script**: A repo-managed shell script that pulls from GitHub, applies infra assets, and restarts the Open WebUI container
- **Infra Assets**: Repo-managed Compose service definition, config templates, nginx templates, and operational scripts stored under `openclaw-infra/` and `openwebui/` in `openclaw`

## Assumptions

- Open WebUI runs on the OpenClaw VPS (12 GB RAM), NOT on the Vikunja VPS (2 GB RAM). The OpenClaw VPS is intended as a multi-app host where OpenClaw maintains deployed apps in a feedback loop, similar to how OpenClaw already maintains Vikunja on the other VPS.
- No local model inference (Ollama) is needed; all LLM access is via remote API providers.
- Andre's existing API keys (OpenAI, Anthropic, OpenRouter, Groq) can be shared between OpenClaw and Open WebUI without provider-side restrictions.
- Open WebUI's built-in user authentication is sufficient; no SSO or external identity provider integration is needed for the initial deployment.
- The Open WebUI container will join the same Docker network as OpenClaw so they can share the host environment and port space, but each service binds distinct ports.
- Open WebUI's official Docker image is used directly (no custom source build), mirroring the OpenClaw image-based deploy pattern.
- OpenClaw will be able to deploy and manage Open WebUI on the same VPS via its Docker socket access, extending the self-maintenance pattern already used for Vikunja.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Andre can open Open WebUI in a browser and complete a full multi-turn conversation within 2 minutes of first access
- **SC-002**: A deploy-from-Git cycle (push to GitHub, SSH into VPS, run deploy script) completes in under 3 minutes and results in the updated Open WebUI running without affecting other services
- **SC-003**: Conversations and user settings survive container restarts and VPS reboots with zero data loss
- **SC-004**: OpenClaw and Open WebUI remain responsive when running concurrently on the 12 GB VPS under normal usage
- **SC-005**: The Open WebUI container recovers automatically after an unexpected crash without manual intervention

## Clarifications

### Session 2026-03-23

- Q: How should Open WebUI be accessed? → A: Subdomain via Caddy with automatic HTTPS (e.g. `chat.yourdomain.com`)
- Q: Who should be able to use Open WebUI? → A: Multi-user for Andre's family. Admin-created accounts only (no public registration). Architecture should support adding paying customers in the future without rework.
- Q: What memory limit for the Open WebUI container? → A: Open WebUI runs on the OpenClaw VPS (12 GB RAM), not the Vikunja VPS (2 GB). Cap at 2 GB mem_limit with 4 GB swap, leaving headroom for OpenClaw and future apps on the same host.
