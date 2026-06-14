# Rock

Rock is an R-centered AI agent docking container for data-science application development.

## What Rock is

AI coding agents are productive but undisciplined about boundaries. Left unconstrained, an agent working inside your shell can read your SSH keys, modify your real project files, write commits, push to remotes, and touch credentials it was never meant to see. The problem is not that the agents are malicious — it is that nothing stops them from drifting outside their intended scope.

Rock solves this with a Docker-based safety workflow. The container gives agents a full R/data-science environment to work in, but the mounts, volumes, and permission model are structured so that only explicitly approved material is reachable. Real project repos, credentials, and publishing actions remain on the host, outside the container entirely.

**Rock is a safety workflow first and a Docker image second.**

```
Rock = R/data-science safety workflow
     + disposable/synthetic workspace
     + reproducible current-R environment
     + persistent user R package volume
     + persistent agent CLI volume
     + HolyClaude as the runtime engine
     + all-agent CLI update helper
     + optional outbound SSH bridge to Hermes / Mac mini
```

The base image is [HolyClaude](https://github.com/coderluii/holyclaude) — a pre-built AI agent runtime container with Claude Code, Codex, and Gemini CLI wired up. Rock adds the R environment, data-science packages, and the safety workflow layer on top. The base image is not the identity of Rock; it is replaceable if a lighter or more auditable base is needed later.

## The boundary model

Rock enforces four explicit boundaries:

```
1. Host system boundary
   Protected by Docker containerization.
   Agents cannot touch the host filesystem unless you explicitly mount it.

2. Data/project boundary
   Protected by mounting only approved workspace folders.
   The default workspace (./workspace/synthetic-only) is meant for
   synthetic or disposable data only — not real project directories.

3. Agent authority boundary
   Protected by permission mode, startup policy, and human checkpoints.
   Agents propose work through /work/proposed; humans review outside Docker.

4. Publishing boundary
   Protected by withholding write-capable repo credentials.
   Agents must not commit, push, release, deploy, or store secrets inside Rock.
```

Docker protects the host from the container. It does not protect mounted paths — anything you mount is inside the agent's reach. Rock makes safe mounting the default.

## Operating modes

**Mode 1 (default): Local-only agent dock**

```
Windows / Linux / macOS host
  -> Docker / Docker Desktop / WSL2
    -> Rock container
      -> ./workspace/synthetic-only only
```

**Mode 2: Local agent dock with Hermes bridge**

```
Windows laptop
  -> WSL2 + Docker Desktop
    -> Rock container
      -> ./workspace/synthetic-only
      -> outbound SSH to Mac mini / Hermes host
```

**Mode 3: Remote-accessed local dock**

```
User device
  -> Tailscale / SSH tunnel / Cloudflare Access
    -> Rock host machine
      -> Rock container web UI
```

Mode 3 must not mean direct public port-forwarding to the web UI. The web UI port is bound to `127.0.0.1:3001` by default.

## Default access model

1. Keep the canonical host repo outside Rock.
2. Use `/workspace` for synthetic or disposable agent work only.
3. Use `/work/scratch` for experiments and intermediate artifacts.
4. Use `/work/proposed` for patches, diffs, summaries, and handoff outputs.
5. Human reviews `/work/proposed` output outside Docker.
6. Human commits, pushes, releases, and deploys outside Docker.

Agents must not commit, push, release, deploy, or store secrets inside Rock.

## Requirements

### Platform

| Platform | Support |
|---|---|
| Windows 10/11 with WSL2 + Docker Desktop | Supported (primary dev platform) |
| macOS with Docker Desktop | Supported |
| Linux with Docker Engine | Supported |

WSL2 is required on Windows — Docker Desktop in Hyper-V mode without WSL2 is not tested.

### Software

| Dependency | Minimum version | Notes |
|---|---|---|
| Docker Engine or Docker Desktop | 24.x+ | Docker Compose V2 must be available as `docker compose` |
| Docker Compose V2 | 2.20+ | Ships with Docker Desktop; install separately on Linux |
| Git | any recent | For cloning this repo and host-side commit/push workflow |

No R, Node.js, or agent CLI installations are required on the host. All tooling runs inside the container.

### Hardware

| Resource | Minimum | Recommended |
|---|---|---|
| RAM | 4 GB available to Docker | 8 GB+ |
| Disk | 10 GB free | 20 GB+ |
| CPU | 2 cores | 4+ cores |

The image build downloads and compiles R packages (`tidyverse`, `shinytest2`, and others), which takes several minutes and is CPU- and memory-intensive. The first `docker compose build` on a cold machine with no cached layers typically takes 10–20 minutes.

The `shm_size: 2g` setting in `compose.yaml` is required by some agent browser-automation tools. Reduce it if your host RAM is constrained.

## Getting started

### Step 1 — Clone the repo

```bash
git clone https://github.com/lennon-li/Rock.git
cd Rock
```

### Step 2 — Copy the environment template

```bash
cp .env.example .env
```

### Step 3 — Add your API keys

Open `.env` and add keys for the agents you want to use. Rock works with any combination — you do not need all of them.

```bash
# Add to .env
ANTHROPIC_API_KEY=sk-ant-...      # Claude Code
OPENAI_API_KEY=sk-...             # Codex
GEMINI_API_KEY=...                # Gemini CLI
```

Never commit `.env` — it is gitignored.

### Step 4 — Build the image

```bash
docker compose build
```

This takes 10–20 minutes on first run (R package compilation). Subsequent builds use the layer cache and are much faster.

### Step 5 — Add material to the workspace

Place only **synthetic, disposable, or explicitly approved** material under:

```
workspace/synthetic-only/
```

Do not put real project repos, real data, SSH keys, cloud credentials, or production configs here.

### Step 6 — Run preflight

Before starting agents, scan the workspace for anything that should not be there:

```bash
docker compose run --rm rock rock-preflight
```

Expected output if clean:

```
ROCK PREFLIGHT: Workspace looks clean.
```

If warnings appear, review the flagged files before proceeding.

### Step 7 — Start the container

```bash
docker compose up -d
```

Check that it is running:

```bash
docker compose ps
```

### Step 8 — Open the agent UI

Navigate to `http://localhost:3001` in your browser. This is the HolyClaude web UI — Claude Code, Codex, and Gemini CLI are available inside.

### Step 9 — Work with agents

Point agents at `/workspace` for file work. Proposed outputs, diffs, and handoff artifacts go in `/work/proposed`. Scratch and experiments go in `/work/scratch`.

After an agent session, review what changed:

```bash
docker compose exec rock rock-summary
```

Human reviews `/work/proposed` output outside Docker. Human commits and pushes outside Docker.

### Step 10 — Update agent CLIs (when needed)

Agent CLIs update frequently. Refresh them without rebuilding the image:

```bash
docker compose exec rock rock-update-agent-clis
```

### Step 11 — Stop the container

```bash
docker compose down
```

Volumes persist — R packages and npm CLIs are retained across restarts.

## File map

```
docker/
  Dockerfile                    R environment, system deps, volume setup
  install-r-packages.R          Default R package installation
  install-extra-agents.sh       Optional extra agent CLI installation at build time
  update-agent-clis.sh          Source for the rock-update-agent-clis runtime command
config/
  agents/AGENTS.md              Agent policy file mounted read-only into the container
  antigravity/                  AGY / Antigravity config mount
  skills/                       Custom skills mounted read-only into the container
  ssh/config.example            SSH config template for Hermes bridge (fill before use)
  ssh/known_hosts.example       Known hosts for Hermes SSH (pin before use)
data/claude/                    Persistent Claude config (mounted to /home/claude/.claude)
workspace/synthetic-only/       Default writable workspace — synthetic/disposable only
compose.yaml                    Main Compose file
compose.hermes.yaml             Optional overlay for Hermes SSH bridge
.env.example                    Environment variable template
scripts/check-scaffold.sh       Validates the scaffold is intact before building
```

## R packages

Rock installs current R from the CRAN apt repository — not the potentially stale distro version. The default package set covers common data-science and development needs:

```
tidyverse    data.table    ggplot2       caret
rmarkdown    quarto        renv          devtools
testthat     lintr         styler        httpgd
shiny        shinytest2
```

`languageserver` is intentionally excluded from the default image.

Users install additional packages on demand from inside the container. Packages are written to the persistent `rock-r-library` Docker volume so they survive container restarts and recreation:

```r
install.packages("pkgname")
```

The configured user library path is `/home/claude/R/library`.

**Volume seeding note:** Docker named volumes are seeded from the image only on first creation. If the `rock-r-library` volume already exists when you rebuild the image, the rebuilt image's base packages do not automatically appear — the existing volume takes precedence. To pick up updated base packages after an image rebuild, either remove the volume (this destroys all user-installed packages) or install the new packages manually inside the running container:

```bash
# Destroy volume and reseed from image (loses user-installed packages)
docker compose down
docker volume rm rock-r-library
docker compose up -d

# Or install manually inside the running container
docker compose exec rock Rscript -e 'install.packages("pkgname")'
```

## Updating agent CLIs

Agent CLIs move fast. Rock includes a runtime helper so users can update tools without rebuilding the image:

```bash
rock-update-agent-clis
```

Default update targets:

```
AGY / Antigravity: official installer from https://antigravity.google/docs/cli-using
Codex:             @openai/codex@latest
Claude Code:       @anthropic-ai/claude-code@latest
Gemini CLI:        @google/gemini-cli@latest
OpenCode:          opencode-ai@latest
```

npm CLIs install to `/home/claude/.local`, backed by the `rock-npm-global` Docker volume. The same volume seeding caveat applies — if the volume already exists, the rebuilt image's CLI files are shadowed by the existing volume. Run `rock-update-agent-clis` inside the container to update CLIs without touching the volume.

Customize the update scope with environment variables:

```bash
# Update only Codex
ROCK_UPDATE_NPM_PACKAGES="@openai/codex@latest" rock-update-agent-clis

# Skip npm CLI updates entirely
ROCK_UPDATE_NPM_PACKAGES=none rock-update-agent-clis

# Enable AGY update
ROCK_UPDATE_AGY=1 rock-update-agent-clis

# Skip AGY update
ROCK_UPDATE_AGY=0 rock-update-agent-clis
```

## AGY / Antigravity CLI

By default, AGY installation is disabled at build time so ordinary builds do not silently download external code. The Antigravity config mount is included regardless.

To enable AGY at build time, after reviewing the official install command:

```env
ROCK_INSTALL_AGY=1
ROCK_AGY_INSTALL_COMMAND="curl -fsSL https://antigravity.google/cli/install.sh | bash"
```

AGY / Antigravity / Argie should be treated as a large-context audit and synthesis lane, read-only by default. Official docs: https://antigravity.google/docs/cli-using

## Hermes bridge

Rock can reach outward to a Hermes / Mac mini host through the optional compose overlay:

```bash
docker compose -f compose.yaml -f compose.hermes.yaml up -d
```

Rules:
- Outbound SSH from Rock to Hermes only — no inbound SSH server inside Rock.
- Do not mount the broad host `~/.ssh` directory.
- Use specific, read-only or restricted keys when needed.
- Pin the Hermes host key in `config/ssh/known_hosts.example` before real use.

## Verification

Run the scaffold check to confirm the directory structure is intact before building:

```bash
./scripts/check-scaffold.sh
```
