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

**Agent efficiency & token-saving tools**
- Fast search (`rg`, `fd`, `rga`), file inspection (`bat`, `jq`, `yq`, `duckdb`), code/structural search (`ast-grep`), repo packing/context (`repomix`, `code2prompt`), and workflow helpers (`just`, `direnv`, `delta`, `difft`, `hyperfine`, `eza`, `dust`, `uv`, `nox`, `tox`, `gh`).

**Requirements:** Docker Desktop (Windows/macOS) or Docker Engine (Linux), 8 GB RAM, 20 GB disk. No R or Node.js needed on the host.

---

## Windows setup

Rock runs on Windows through WSL 2 (Windows Subsystem for Linux). You have two options for running Docker with WSL 2:

### Docker Setup Options Comparison

| Feature / Metric | Option A: Docker Desktop | Option B: Native WSL 2 Docker Engine |
|---|---|---|
| **License & Cost** | Free for personal/small business; paid subscription for large enterprises. | 100% Free and Open Source (Apache 2.0). |
| **Resource Usage** | Higher RAM/CPU overhead (runs helper services on both Windows and WSL 2). | Extremely lightweight (runs natively as a Linux process inside WSL 2). |
| **User Interface** | Full graphical dashboard GUI for container management. | Command-line only (`docker` and `docker compose`). |
| **Management** | Automates background startup, port forwarding, and VM lifecycle. | Requires manual daemon startup (`sudo service docker start`) unless systemd is enabled. |

---

### Step 1 — Install WSL 2 (Required for both)

Open PowerShell as Administrator (right-click Start → Windows PowerShell (Admin)) and run:

```powershell
wsl --install
```

This installs WSL 2 and Ubuntu automatically. Restart your computer when prompted. If you already have WSL installed, ensure it is version 2:

```powershell
wsl --set-default-version 2
```

---

### Step 2 — Set up Ubuntu (Required for both)

After restarting, Ubuntu will open automatically and ask you to create a username and password. This is your Linux account inside WSL — it does not need to match your Windows account.

If it does not open automatically, find **Ubuntu** in the Start menu and launch it.

---

### Choose your installation path:

#### Option A — Docker Desktop (Recommended for GUI Users)

1. **Download and install Docker Desktop:** Go to [https://www.docker.com/products/docker-desktop](https://www.docker.com/products/docker-desktop) and download the Windows installer. Make sure **Use WSL 2 instead of Hyper-V** is checked during installation.
2. **Enable Integration:** Open Docker Desktop. Go to `Settings → Resources → WSL Integration`, toggle integration on for your Ubuntu distribution, and click **Apply & Restart**.
3. **Open Terminal:** Open the **Ubuntu** terminal from your Start menu.
4. **Verify:** In the Ubuntu terminal, run:
   ```bash
   docker --version
   docker compose version
   ```

---

#### Option B — Native Docker Engine (Recommended for 100% WSL users)

1. **Open Terminal:** Open the **Ubuntu** terminal from your Start menu.
2. **Install Docker Engine:** Run the following commands to install native Linux Docker:
   ```bash
   # Remove conflicting packages
   for pkg in docker.io docker-doc docker-compose podman-docker containerd runc; do sudo apt-get remove $pkg; done

   # Set up Docker's apt repository
   sudo apt-get update
   sudo apt-get install -y ca-certificates curl gnupg
   sudo install -m 0755 -d /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   sudo chmod a+r /etc/apt/keyrings/docker.gpg

   echo \
     "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
     $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
     sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

   # Install Docker CE packages
   sudo apt-get update
   sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
   ```
3. **Set permissions:** Add your WSL user to the `docker` group so you don't need `sudo` for container commands:
   ```bash
   sudo usermod -aG docker $USER
   ```
   *(Close the terminal and open a new Ubuntu window to apply group changes).*
4. **Start the daemon:** Start Docker inside WSL:
   ```bash
   sudo service docker start
   ```
5. **Verify:** Run:
   ```bash
   docker --version
   docker compose version
   ```

---

**You are now ready to proceed with the setup below.**

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

**Login with a ChatGPT Plus/Pro subscription (no API key needed):**

Simply run Codex:
```bash
docker compose exec rock codex
```
If no active session exists, this prompts you to sign in. Select **Sign in with ChatGPT** (or **Sign in with Device Code** for headless environments) to authenticate via the browser.

**Or set an API key in `.env`:**

```
OPENAI_API_KEY=sk-...
```

---

## Using OpenCode

**Login with OpenCode auth (no API key needed):**

```bash
docker compose exec rock opencode auth login
```
This manages provider API keys or subscription sessions via browser authentication.

---

## Using AGY / Antigravity

**Login with Google AI / Google Cloud subscription (no API key needed):**

Simply run `agy` to trigger the interactive browser-based Google OAuth flow:
```bash
docker compose exec rock agy
```

**Or set an API key in `.env`:**

```
GEMINI_API_KEY=...
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

---

## Agent efficiency tools

Verify which efficiency and token-saving tools are installed and which are missing:

```bash
docker compose exec rock rock-check-agent-tools
```

Install or update all required agent tools manually inside the container (this is run automatically during image build):

```bash
docker compose exec rock rock-install-missing-agent-tools
```
