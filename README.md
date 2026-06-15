# Rock

A Docker container for agentic R-based data science. Run Claude Code, Codex, and Gemini CLI alongside a full R environment — agents work inside the container, your files and credentials stay on your machine.

## What's included

**AI agents**
- Claude Code (Anthropic)
- Codex (OpenAI)
- Gemini CLI (Google)
- OpenCode
- AGY / Antigravity (optional)

**R environment**
- Current R from CRAN (not the distro-stale version)
- tidyverse, data.table, ggplot2, caret, rmarkdown, quarto, renv, devtools, testthat, lintr, styler, httpgd, shiny, shinytest2
- Persistent user R library — packages survive container restarts

**Safety**
- Workspace is isolated from your host by default
- Agents propose changes to `/work/proposed`; you review and commit on the host
- `rock-preflight` scans for secrets before agent sessions
- `rock-summary` shows what changed after a session

**Requirements:** Docker Desktop (Windows/macOS) or Docker Engine (Linux), 8 GB RAM, 20 GB disk. No R or Node.js needed on the host.

---

## Setup

**1. Clone and configure**

```bash
git clone https://github.com/lennon-li/Rock.git
cd Rock
cp .env.example .env
```

Open `.env` and add your API keys:

```
ANTHROPIC_API_KEY=sk-ant-...
OPENAI_API_KEY=sk-...
GEMINI_API_KEY=...
```

**2. Build**

```bash
docker compose build
```

First build takes 10–20 minutes (R package compilation). Subsequent builds are cached.

**3. Start**

```bash
docker compose up -d
```

Open `http://localhost:3001` — this is the agent web UI.

**4. Stop**

```bash
docker compose down
```

---

## Using R

Open a terminal inside the container and start R:

```bash
docker compose exec rock R
```

Or run a script:

```bash
docker compose exec rock Rscript /workspace/analysis.R
```

**Install a package:**

```bash
docker compose exec rock Rscript -e 'install.packages("praise")'
```

Packages install to `/home/claude/R/library`, backed by a persistent Docker volume. They survive container restarts.

---

## Using Claude Code

**Login with a Claude subscription (no API key needed):**

```bash
docker compose exec rock claude login
```

Copy the URL printed, open it in your browser, authenticate. The session token persists in `./data/claude/` on your host.

**Or set an API key in `.env`:**

```
ANTHROPIC_API_KEY=sk-ant-...
```

Claude Code is available at `http://localhost:3001` via the web UI, or run it directly:

```bash
docker compose exec rock claude
```

---

## Using Codex

Set your key in `.env`:

```
OPENAI_API_KEY=sk-...
```

Then run inside the container:

```bash
docker compose exec rock codex
```

---

## GitHub access

**Clone a repo into the workspace:**

```bash
docker compose exec rock bash -c "cd /workspace && git clone https://github.com/your-org/your-repo.git"
```

**With a personal access token (HTTPS):**

Add to `.env`:

```
GITHUB_TOKEN=ghp_...
```

Then configure git inside the container:

```bash
docker compose exec rock bash -c "git config --global credential.helper store && echo 'https://your-user:$GITHUB_TOKEN@github.com' > ~/.git-credentials"
```

**With SSH:** fill in `config/ssh/config.example` with your GitHub SSH key, then start with the SSH overlay:

```bash
docker compose -f compose.yaml -f compose.ssh.yaml up -d
```

> Agents should not commit or push. Review outputs in `/work/proposed` and commit from your host.

---

## Mounting a local folder

To give agents access to a local directory, add a bind mount to `compose.yaml` under `volumes:`:

```yaml
volumes:
  - ./workspace/synthetic-only:/workspace
  - /path/to/your/local/folder:/work/myproject   # add this line
```

Then restart:

```bash
docker compose down && docker compose up -d
```

The folder is accessible inside the container at `/work/myproject`.

> Only mount folders you are comfortable exposing to agents. Agents can read and write anything inside a mounted path.

---

## Update agent CLIs

Agent CLIs release frequently. Update without rebuilding:

```bash
docker compose exec rock rock-update-agent-clis
```

---

## Safety helpers

Scan the workspace for secrets before a session:

```bash
docker compose exec rock rock-preflight
```

Review what changed after a session:

```bash
docker compose exec rock rock-summary
```
