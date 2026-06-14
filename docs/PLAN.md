# Rock Project Plan

## Purpose

Rock is an R-centered AI agent docking container for data-science application development.

The goal is not just to build a Docker image. The goal is to create a controlled workflow where AI coding agents can work productively while protecting:

1. the host system environment,
2. real project/data folders,
3. agent authority boundaries, and
4. publishing credentials/actions.

Rock should let agents work quickly inside a container, but only against explicitly mounted folders, ideally folders containing synthetic or disposable data.

## Core Design Principle

Rock is a safety workflow first and a Docker image second.

Current implementation direction:

```text
Rock = R/data-science safety workflow
     + disposable/synthetic workspace
     + reproducible current-R environment
     + persistent user package/CLI volumes
     + HolyClaude as the initial runtime engine
     + all-agent CLI update helper
     + optional outbound SSH bridge to Hermes / Mac mini
```

HolyClaude is the current base image, not the identity of Rock. Rock should remain replaceable later. If HolyClaude becomes too broad, too permissive, or too hard to audit, Rock should be able to move to `rocker/r-ver` or another minimal Linux base while keeping the same mounted workspace/config model.

## Target Architecture

Rock supports three operating modes.

```text
Mode 1: Local-only agent dock
  Windows / Linux / macOS host
    -> Docker / Docker Desktop / WSL2
      -> Rock container
        -> mounted synthetic/disposable workspace only

Mode 2: Local agent dock with Hermes bridge
  Windows laptop
    -> WSL2 + Docker Desktop
      -> Rock container
        -> mounted synthetic/disposable workspace only
        -> outbound SSH to Mac mini / Hermes

Mode 3: Remote-accessed local dock
  User device
    -> Tailscale / SSH tunnel / Cloudflare Access
      -> Rock host
        -> Rock container web UI
```

Default mode is Mode 1.

Mode 2 is allowed when Rock needs to talk to a long-running Hermes host. The bridge should be outbound SSH from Rock to Hermes, not inbound SSH into Rock.

Mode 3 must not mean public port-forwarding directly to the web UI.

## Boundary Model

Rock separates four boundaries:

```text
1. Host system boundary
   Protected by Docker containerization.

2. Data/project boundary
   Protected by mounting only approved workspace folders.

3. Agent authority boundary
   Protected by permission mode, startup policy, and human checkpoints.

4. Publishing boundary
   Protected by withholding write-capable repo credentials and keeping commits/pushes human-owned.
```

Important: Docker protects the host environment, but it does not automatically protect mounted data. Any mounted path is inside the agent's reach. Therefore Rock should make safe mounting the default.

## Access Model

Default workflow:

1. Keep the canonical host repo outside Rock.
2. Use `/workspace` for synthetic or disposable work.
3. Use `/work/scratch` for experiments.
4. Use `/work/proposed` for patches, diffs, summaries, and handoff artifacts.
5. Human reviews outputs outside Docker.
6. Human commits, pushes, releases, and deploys outside Docker.

Agents must not commit, push, release, deploy, or store secrets inside Rock.

## Implemented Scaffold

Current repository scaffold:

```text
docker/
  Dockerfile
  install-r-packages.R
  install-extra-agents.sh
  update-agent-clis.sh
config/
  agents/AGENTS.md
  antigravity/README.md
  skills/.gitkeep
  ssh/config.example
  ssh/known_hosts.example
data/claude/.gitkeep
workspace/synthetic-only/.gitkeep
compose.yaml
compose.hermes.yaml
.env.example
scripts/check-scaffold.sh
README.md
docs/PLAN.md
docs/AGENT_ACCESS_MODEL.md
```

## Docker Direction

Use HolyClaude first:

```dockerfile
FROM coderluii/holyclaude:latest
```

Pin the base image before stable/repeated use. `latest` is acceptable during prototype iteration only.

The Dockerfile installs:

- current R from the CRAN Ubuntu apt repository,
- R development headers,
- system libraries required by common R packages,
- `openssh-client`,
- persistent user library path `/home/claude/R/library`,
- persistent npm global path `/home/claude/.local`,
- CLI updater command `rock-update-agent-clis`.

## R Runtime Direction

Rock should install current R from the CRAN Ubuntu apt repository rather than relying on potentially stale distro packages.

Default R package set:

```text
tidyverse
data.table
ggplot2
caret
rmarkdown
quarto
renv
devtools
testthat
lintr
styler
httpgd
shiny
shinytest2
```

`languageserver` is intentionally excluded from the default image.

Users can install additional packages on demand:

```r
install.packages("pkgname")
```

The configured user library is:

```text
/home/claude/R/library
```

That path is backed by the `rock-r-library` Docker volume, so user-installed packages survive container recreation. Docker named volumes are seeded from the image only when the volume is first created; if `rock-r-library` already exists, a rebuilt image's base R packages at `/home/claude/R/library` are hidden by the existing volume. To pick up new base packages after an image update, either remove the volume intentionally, which destroys user-installed packages, or manually install the new packages inside the running container.

```bash
docker volume rm rock-r-library && docker compose up -d
Rscript -e 'install.packages(c("pkgname"), repos = "https://cloud.r-project.org")'
```

## Agent CLI Direction

Agent CLIs update frequently. Rock should not require a full image rebuild for every CLI refresh.

The image includes:

```bash
rock-update-agent-clis
```

Default CLI update targets:

```text
AGY / Antigravity: official installer from https://antigravity.google/docs/cli-using
Codex: @openai/codex@latest
Claude Code: @anthropic-ai/claude-code@latest
Gemini CLI: @google/gemini-cli@latest
OpenCode: opencode-ai@latest
```

The npm global prefix is:

```text
/home/claude/.local
```

It is backed by the `rock-npm-global` Docker volume, so the container user can update npm-based CLIs without writing into system directories. Docker named volumes are seeded from the image only when the volume is first created; if `rock-npm-global` already exists, a rebuilt image's CLI files at `/home/claude/.local` are hidden by the existing volume. To pick up new image-provided CLI files after an image update, either remove the volume intentionally, which destroys user-installed CLI state, or update the CLIs inside the running container.

```bash
docker volume rm rock-npm-global && docker compose up -d
rock-update-agent-clis
```

Users can customize the update scope:

```bash
ROCK_UPDATE_NPM_PACKAGES="@openai/codex@latest" rock-update-agent-clis
ROCK_UPDATE_NPM_PACKAGES=none rock-update-agent-clis
```

AGY install/update is controlled separately:

```bash
ROCK_UPDATE_AGY=1 rock-update-agent-clis
ROCK_UPDATE_AGY=0 rock-update-agent-clis
```

Build-time AGY install remains opt-in:

```env
ROCK_INSTALL_AGY=0
ROCK_AGY_INSTALL_COMMAND="curl -fsSL https://antigravity.google/cli/install.sh | bash"
```

## Compose Direction

`compose.yaml` should mount only what the agent is allowed to touch.

Current local-only pattern:

```text
./data/claude                  -> /home/claude/.claude
./config/skills                -> /opt/rock/skills:ro
./config/agents                -> /opt/rock/agents:ro
./config/antigravity           -> /home/claude/.gemini/antigravity-cli:ro
./workspace/synthetic-only     -> /workspace
rock-proposed                  -> /work/proposed
rock-scratch                   -> /work/scratch
rock-r-library                 -> /home/claude/R/library
rock-npm-global                -> /home/claude/.local
```

The web UI port must bind locally:

```text
127.0.0.1:3001:3001
```

For high-trust synthetic-only work, `bypassPermissions` can be considered, but only after the mounted workspace is verified to contain no sensitive or real data.

## Hermes / Mac mini SSH Bridge

Rock may connect outward to Hermes / Mac mini through the optional overlay:

```bash
docker compose -f compose.yaml -f compose.hermes.yaml up -d
```

Rules:

- outbound SSH only,
- no SSH server inside Rock by default,
- do not mount broad host `~/.ssh`,
- use specific read-only/restricted keys when needed,
- pin host keys in `config/ssh/known_hosts.example` before real use.

## Current Decision Log

- Build on HolyClaude first.
- Keep HolyClaude replaceable later.
- Use current R from CRAN Ubuntu apt repo.
- Include `shinytest2`.
- Exclude `languageserver` from default R packages.
- Let users install additional R packages into persistent user library.
- Add all-agent CLI update helper because CLIs change frequently.
- Keep AGY build-time install opt-in.
- Keep `/workspace` writable but treat it as synthetic/disposable only.
- Keep commits, pushes, releases, deployments, and publishing human-owned.
- Support Windows through WSL2 + Docker Desktop.
- Support Hermes through optional outbound SSH, not public/inbound SSH.

## Phase Plan

### Phase 1 — Scaffold and Static Validation

Status: implemented.

- Add Dockerfile and install scripts.
- Add Compose files.
- Add config/workspace/data skeletons.
- Add scaffold check script.
- Validate shell syntax and Compose rendering.

### Phase 2 — First Container Build

Next.

- Run `docker compose build`.
- Confirm current R installs correctly.
- Confirm default R packages install correctly.
- Confirm `shinytest2` installation.
- Confirm `languageserver` is not installed by default.
- Confirm user can install an extra R package into `/home/claude/R/library`.
- Confirm npm global updates go to `/home/claude/.local`.

### Phase 3 — Runtime Smoke Tests

- Start container with `docker compose up -d`.
- Check `R --version`.
- Check `.libPaths()` includes `/home/claude/R/library`.
- Check `install.packages()` works for a small package.
- Check `rock-update-agent-clis` runs in dry/safe mode or documented mode.
- Check local-only port binding.
- Check `/work/proposed` and `/work/scratch` write permissions.

### Phase 4 — Safety Preflight

- Add workspace preflight scanner for obvious sensitive files:
  - `.env`,
  - SSH keys,
  - cloud credentials,
  - large raw data,
  - production-looking config,
  - hidden auth directories.
- Warn before agent work if suspicious files are mounted.
- Add post-run diff/status summary helper.

### Phase 5 — Hermes Bridge Validation

- Fill real SSH config only after approval.
- Pin Hermes host key.
- Confirm outbound SSH works.
- Confirm Rock cannot access broader host data through the bridge.

### Phase 6 — Base Image Hardening

- Pin HolyClaude image digest/version.
- Add build labels and version metadata.
- Consider `rock-minimal` alternative:

```text
rock-minimal = rocker/r-ver + selected tools only
rock-holy    = HolyClaude derivative
```

Keep the same mounted config and workspace layout across both.
