# Rock Project Plan

## Purpose

Rock is an R-centered agent docking container for data-science application development.

The goal is not simply to build another development container. The goal is to create a controlled workflow where AI coding agents can work productively while protecting both:

1. the host system environment, and
2. the data/project boundary.

Rock should let agents work quickly inside a container, but only against explicitly mounted folders, ideally folders containing synthetic or non-sensitive data.

## Core Design Principle

Rock is a safety workflow first and a Docker image second.

The current recommended implementation is:

```text
Rock = R/data-science safety workflow
     + agent configuration policy
     + mounted synthetic workspace
     + reproducible R environment
     + HolyClaude as the initial runtime engine
     + optional SSH bridge to Hermes / Mac mini
```

HolyClaude should be treated as the current base image, not as the identity of the project.

This keeps Rock replaceable later. If HolyClaude becomes too broad, too permissive, or too hard to audit, Rock should be able to move to a cleaner base such as `rocker/r-ver` or another minimal Linux image.

## Target Architecture

Rock should support three operating modes.

```text
Mode 1: Local-only agent dock
  Windows / Linux / macOS host
    -> Docker / Docker Desktop / WSL2
      -> Rock container
        -> mounted synthetic workspace only

Mode 2: Local agent dock with Hermes bridge
  Windows laptop
    -> WSL2 + Docker Desktop
      -> Rock container
        -> mounted synthetic workspace only
        -> outbound SSH to Mac mini / Hermes

Mode 3: Remote-accessed local dock
  User device
    -> Tailscale / SSH tunnel / Cloudflare Access
      -> Rock host
        -> Rock container web UI
```

The default should be Mode 1.

Mode 2 is allowed when Rock needs to talk to a long-running Hermes host, for example a Mac mini that stores persistent agent workflows, memory, logs, or coordination services.

Mode 3 should never mean public port-forwarding directly to the web UI.

## System Boundary Model

Rock separates four boundaries:

```text
1. Host system boundary
   Protected by Docker containerization.

2. Data/project boundary
   Protected by mounting only approved workspace folders.

3. Agent authority boundary
   Protected by permission mode, startup policy, and human checkpoints.

4. Remote-control boundary
   Protected by local-only ports, SSH, Tailscale, or Cloudflare Access.
```

The important point: the container protects the host environment, but it does not automatically protect mounted data. Any mounted path is inside the agent's reach. Therefore Rock must make safe mounting the default.

## Recommendation

Start by building Rock as a thin derivative of HolyClaude.

Do not rebuild all tools from scratch at the beginning.

HolyClaude already solves many operational problems:

- Claude Code
- Codex CLI
- Gemini CLI
- OpenCode
- CloudCLI web UI
- browser/headless Chromium support
- GitHub CLI
- Python/data tools
- UID/GID permission mapping
- persistent credentials and config
- mounted workspace
- permission modes such as `acceptEdits` and `bypassPermissions`

Rebuilding all of this immediately would shift effort away from Rock's real value: safe R/data-science agent workflows.

## Layering Strategy

Use Docker layers only for slow-changing components.

Use mounted folders for fast-changing components.

### Baked into the image

These are relatively stable and expensive to install repeatedly:

```text
- HolyClaude base runtime
- R
- system libraries needed by R packages
- heavy or stable R packages
- stable CLI tools not already available in HolyClaude
- Quarto or Pandoc if required
- openssh-client if not already present in the base image
```

### Mounted from the host

These should stay outside the image so they can be updated without rebuilding:

```text
- project workspace
- synthetic data
- agent skills
- prompts and instructions
- Claude/Codex/OpenCode configuration
- package manifests
- local test projects
- optional read-only SSH client keys for Hermes access
```

### Updated at runtime only when acceptable

These can be installed during experiments, but should later be moved into the image or lockfile if they become part of the stable workflow:

```text
- temporary R packages
- temporary npm/pip packages
- experimental agent tools
- project-specific utilities
```

## Proposed Repository Structure

```text
Rock/
├── docker/
│   ├── Dockerfile
│   ├── install-r-packages.R
│   └── install-extra-agents.sh
├── config/
│   ├── claude/
│   ├── codex/
│   ├── opencode/
│   ├── skills/
│   └── ssh/
│       ├── config.example
│       └── known_hosts.example
├── data/
│   └── claude/
├── workspace/
│   └── synthetic-only/
├── docs/
│   └── PLAN.md
├── compose.yaml
├── compose.hermes.yaml
├── .env.example
├── renv.lock
└── README.md
```

## Initial Dockerfile Direction

Use HolyClaude as the first base image.

Pin the base image when moving beyond experimentation. Avoid relying on `latest` for stable work.

```dockerfile
FROM coderluii/holyclaude:latest

USER root

RUN apt-get update && apt-get install -y \
    r-base r-base-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libjpeg-dev \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

COPY docker/install-r-packages.R /tmp/install-r-packages.R
RUN Rscript /tmp/install-r-packages.R

USER claude
WORKDIR /workspace
```

## Compose Direction

The compose file should mount only what the agent is allowed to touch.

Initial local-only pattern:

```yaml
services:
  rock:
    build:
      context: .
      dockerfile: docker/Dockerfile
    container_name: rock
    hostname: rock
    restart: unless-stopped
    shm_size: 2g
    ports:
      - "127.0.0.1:3001:3001"
    volumes:
      - ./data/claude:/home/claude/.claude
      - ./config/skills:/opt/rock/skills:ro
      - ./workspace/synthetic-only:/workspace
    environment:
      - TZ=America/Toronto
      - PUID=1000
      - PGID=1000
      - HOLYCLAUDE_CODEX_CHAT_PERMISSION_MODE=acceptEdits
      - HOLYCLAUDE_CODEX_CLI_PERMISSION_MODE=acceptEdits
```

For high-trust synthetic-only work, `bypassPermissions` can be considered, but only after the mounted workspace is verified to contain no real sensitive data.

## Hermes / Mac mini SSH Bridge

Rock may need to connect outward to a Mac mini running Hermes.

This should be outbound SSH from Rock to the Mac mini, not inbound SSH into Rock.

Preferred pattern:

```text
Rock container -> SSH client -> Mac mini / Hermes
```

Avoid running an SSH server inside Rock unless there is a specific operational need.

Recommended SSH mount pattern:

```yaml
services:
  rock:
    volumes:
      - ./data/claude:/home/claude/.claude
      - ./config/skills:/opt/rock/skills:ro
      - ./config/ssh:/home/claude/.ssh:ro
      - ./workspace/synthetic-only:/workspace
```

Example command from inside Rock:

```bash
ssh hermes@mac-mini.local
```

or with an explicit key:

```bash
ssh -i ~/.ssh/hermes_key hermes@mac-mini.local
```

SSH rules:

```text
- Mount SSH keys read-only.
- Use a dedicated key for Hermes, not a broad personal key.
- Prefer restricted Mac mini user permissions.
- Do not mount the host's entire ~/.ssh directory by default.
- Put known hosts in config/ssh/known_hosts.
- Keep Hermes access optional; Rock should still run without it.
```

## Inbound Access to Rock

Default inbound access should be through:

```text
- local browser to 127.0.0.1:3001
- docker exec -it rock bash
- HolyClaude / CloudCLI web terminal
```

Avoid adding SSH server access into Rock by default.

If SSH into the container is ever required, it should be local-only:

```yaml
ports:
  - "127.0.0.1:2222:22"
```

and treated as an advanced profile, not the default.

## Windows Support

Rock should explicitly support Windows through WSL2 and Docker Desktop.

Recommended Windows setup:

```text
Windows 11
  -> WSL2 backend
    -> Docker Desktop
      -> Rock repo cloned inside WSL filesystem
        -> docker compose up -d
```

Recommended repo location:

```bash
~/projects/Rock
```

Avoid using `/mnt/c/...` for the active repo and workspace when possible, because file watching, permissions, and filesystem performance are usually worse through the Windows-mounted filesystem.

Windows-specific notes:

```text
- Use Docker Desktop with WSL2 backend.
- Clone Rock inside Ubuntu/WSL, not under C:\Users if possible.
- Keep mounted synthetic workspace under the WSL filesystem.
- Browser access should remain localhost-bound.
- SSH from Rock to Mac mini should work if the Windows/WSL network can resolve or reach the Mac mini.
```

## Data Boundary Policy

Rock should make the safe path easy and the risky path obvious.

Recommended default:

```text
/workspace = synthetic-only project workspace
```

Avoid mounting broad locations such as:

```text
- home directory
- Documents
- Desktop
- Downloads
- entire GitHub folder
- cloud-synced personal folders
- host ~/.ssh
- folders containing real PHI, PII, credentials, or production data
```

Allowed initial workspace:

```text
./workspace/synthetic-only
```

Future design may add explicit mount profiles:

```text
profile: synthetic      # full automation allowed
profile: project-safe   # edits allowed, shell commands reviewed
profile: sensitive      # read-only or human approval required
profile: production     # no direct agent write access
profile: hermes-bridge  # synthetic workspace + outbound SSH to Hermes
```

## Permission Policy

Suggested default:

```text
acceptEdits
```

Meaning:

- agents can propose and make file edits,
- shell commands still require more caution,
- destructive actions should remain reviewable.

`bypassPermissions` should be limited to synthetic-only workspaces and disposable project folders.

Use this rule:

```text
If the agent can touch real data, do not use full auto-accept.
If the agent can only touch synthetic/disposable data, full auto-accept may be acceptable.
If the agent also has SSH access to Hermes, treat it as higher authority than local-only synthetic mode.
```

## Update Strategy

Rock should support separate update rhythms.

### Base image updates

HolyClaude updates should be deliberate:

```bash
docker pull coderluii/holyclaude:<tag>
docker compose build --pull
docker compose up -d
```

Use pinned versions once stable.

### R package updates

Use `renv` or a package manifest.

Possible approaches:

```text
- renv.lock for project reproducibility
- install-r-packages.R for base image packages
- optional local package cache volume
```

### Skills/config updates

Do not rebuild the image for these.

Mount them:

```text
./config/skills:/opt/rock/skills:ro
```

### SSH/Hermes config updates

Do not rebuild the image for these.

Mount them:

```text
./config/ssh:/home/claude/.ssh:ro
```

## Phased Roadmap

### Phase 0 — Decision Record

- Record the architecture decision: build on HolyClaude first.
- Document why Rock remains base-image replaceable.
- Define safe workspace assumptions.
- Document Windows + WSL2 as the first supported host path.
- Document optional outbound SSH bridge to Mac mini / Hermes.

### Phase 1 — Minimal Running Container

- Add Dockerfile based on HolyClaude.
- Add R and required system libraries.
- Add compose file.
- Mount only `workspace/synthetic-only`.
- Confirm Claude/Codex/OpenCode can see and edit only the mounted workspace.
- Confirm container runs on Windows through WSL2 + Docker Desktop.

### Phase 2 — R/Data-Science Layer

- Add core R packages.
- Add `renv` support.
- Add test R package skeleton.
- Add simple synthetic data workflow.
- Add smoke tests for R, package install, and file permissions.

### Phase 3 — Agent Workflow Layer

- Add skills/instructions folder.
- Add default agent policies.
- Add startup checklist.
- Add `acceptEdits` and `bypassPermissions` profiles.
- Add command wrappers for safe project startup.

### Phase 4 — Safety Layer

- Add preflight check that warns if workspace contains suspicious files:
  - `.env`
  - credentials
  - real data filenames
  - large untracked raw data
  - cloud sync metadata
  - host SSH keys
- Add backup/snapshot command before agent auto-work.
- Add post-run diff summary.
- Add human approval checkpoint before pushing to GitHub.

### Phase 5 — Hermes Bridge

- Add optional `compose.hermes.yaml`.
- Add SSH config template.
- Add known-hosts setup instructions.
- Add a restricted Hermes SSH key workflow.
- Add smoke test: Rock can SSH to Hermes but cannot access broader host data.

### Phase 6 — Independence Option

If HolyClaude becomes limiting, build a second base:

```text
rock-minimal = rocker/r-ver + selected tools only
rock-holy    = HolyClaude derivative
```

Keep the same mounted config and workspace layout so the user workflow stays stable.

## Immediate Next Files to Add

```text
README.md
compose.yaml
compose.hermes.yaml
.env.example
docker/Dockerfile
docker/install-r-packages.R
config/skills/README.md
config/ssh/config.example
config/ssh/known_hosts.example
workspace/synthetic-only/.gitkeep
```

## Current Decision

Build on HolyClaude first.

Do not rebuild from scratch yet.

Design Rock so that HolyClaude can be replaced later without changing the core project concept.

Support Windows through WSL2 + Docker Desktop.

Support Mac mini / Hermes through optional outbound SSH from Rock, not by default exposing Rock over SSH.
