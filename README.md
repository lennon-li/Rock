# Rock

Rock is an R-centered AI agent docking container for data-science application development.

Rock is a safety workflow first and a Docker image second. The default setup gives agents a disposable/synthetic workspace, persistent container-owned scratch/proposed volumes, and a reproducible R environment while keeping real host projects and publishing credentials outside the container.

## What is included

- HolyClaude-derived base image.
- Current R from the CRAN Ubuntu apt repository plus common data-science/development packages.
- Local-only web UI port binding: `127.0.0.1:3001:3001`.
- Disposable workspace mount: `./workspace/synthetic-only:/workspace`.
- Proposed-output and scratch Docker volumes:
  - `/work/proposed`
  - `/work/scratch`
- Read-only agent/skills/config mounts.
- Optional AGY / Antigravity config lane.
- Optional outbound SSH overlay for Hermes / Mac mini.

## Current scaffold

```text
docker/
  Dockerfile
  install-r-packages.R
  install-extra-agents.sh
config/
  agents/AGENTS.md
  antigravity/README.md
  skills/
  ssh/config.example
  ssh/known_hosts.example
data/claude/
workspace/synthetic-only/
compose.yaml
compose.hermes.yaml
.env.example
scripts/check-scaffold.sh
```

## First run

```bash
cp .env.example .env
docker compose build
docker compose up -d
```

Then place only synthetic, disposable, or explicitly approved project material under:

```text
workspace/synthetic-only/
```



## Updating agent CLIs

Agent CLIs move fast. Rock includes a runtime helper so users can update tools without rebuilding the image:

```bash
rock-update-agent-clis
```

By default, the helper updates/install these known agent CLIs:

```text
AGY / Antigravity: official installer from https://antigravity.google/docs/cli-using
Codex: @openai/codex@latest
Claude Code: @anthropic-ai/claude-code@latest
Gemini CLI: @google/gemini-cli@latest
OpenCode: opencode-ai@latest
```

The npm global prefix is `/home/claude/.local`, backed by the `rock-npm-global` Docker volume, so the container user can update CLIs without writing into system directories.

To customize or skip npm CLI updates:

```bash
ROCK_UPDATE_NPM_PACKAGES="@openai/codex@latest" rock-update-agent-clis
ROCK_UPDATE_NPM_PACKAGES=none rock-update-agent-clis
```

## R packages

Rock installs a useful default R stack at image build time:

```text
tidyverse, data.table, ggplot2, caret, rmarkdown, quarto, renv,
devtools, testthat, lintr, styler, httpgd, shiny, shinytest2
```

`languageserver` is intentionally not part of the default package set.

Users can install additional packages as needed from inside the container. The user library is persistent through the `rock-r-library` Docker volume:

```r
install.packages("pkgname")
```

The configured user library is:

```text
/home/claude/R/library
```

## AGY / Antigravity CLI

Rock includes an AGY/Antigravity configuration mount and installer hook.

By default, AGY installation is disabled so ordinary builds do not silently download external code. The opt-in Linux/macOS install command below comes from the official Antigravity CLI docs.

To enable it after reviewing the official install command:

```env
ROCK_INSTALL_AGY=1
ROCK_AGY_INSTALL_COMMAND="curl -fsSL https://antigravity.google/cli/install.sh | bash"
```

The installer requires the command to put `agy` on `PATH`; otherwise the build fails. Official docs source: https://antigravity.google/docs/cli-using

AGY / Antigravity / Argie should be treated as a large-context audit/synthesis lane and read-only by default.

## Hermes bridge

Use the optional compose overlay for outbound SSH only:

```bash
docker compose -f compose.yaml -f compose.hermes.yaml up -d
```

Do not run an SSH server inside Rock unless there is a specific reviewed operational need.

## Safety model

Default workflow:

1. Keep the canonical host repo outside Rock.
2. Use `/workspace` for synthetic or disposable work.
3. Let agents create diffs, patches, logs, and summaries in `/work/proposed`.
4. Human reviews outside Docker.
5. Human commits and pushes outside Docker.

Agents must not commit, push, release, deploy, or store secrets inside Rock.

## Verification

Run the scaffold check:

```bash
./scripts/check-scaffold.sh
```
