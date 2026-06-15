#!/usr/bin/env bash
set -euo pipefail

required_files=(
  docker/Dockerfile
  docker/install-r-packages.R
  docker/install-extra-agents.sh
  docker/update-agent-clis.sh
  compose.yaml
  compose.ssh.yaml
  .env.example
  config/ssh/config.example
  config/ssh/known_hosts.example
  config/agents/AGENTS.md
  config/antigravity/README.md
  workspace/synthetic-only/.gitkeep
  data/claude/.gitkeep
)

for path in "${required_files[@]}"; do
  if [[ ! -e "$path" ]]; then
    echo "missing required scaffold file: $path" >&2
    exit 1
  fi
done

grep -q "FROM coderluii/holyclaude" docker/Dockerfile
grep -q "install-extra-agents.sh" docker/Dockerfile
grep -q "rock-update-agent-clis" docker/Dockerfile
grep -q "ROCK_UPDATE_AGY" docker/update-agent-clis.sh
grep -q "@openai/codex@latest" docker/update-agent-clis.sh
grep -q "@anthropic-ai/claude-code@latest" docker/update-agent-clis.sh
grep -q "@google/gemini-cli@latest" docker/update-agent-clis.sh
grep -q "opencode-ai@latest" docker/update-agent-clis.sh
grep -q "rock-npm-global" compose.yaml
grep -q "NPM_CONFIG_PREFIX=/home/claude/.local" docker/Dockerfile
grep -q "Updating agent CLIs" README.md
grep -q "r-base" docker/Dockerfile
grep -q "CRAN__linux__ubuntu" docker/Dockerfile
grep -q "shinytest2" docker/install-r-packages.R
if grep -q "languageserver" docker/install-r-packages.R; then
  echo "languageserver should not be part of the default package set" >&2
  exit 1
fi
grep -q "R_LIBS_USER=/home/claude/R/library" .env.example
grep -q "ROCK_UPDATE_AGY=1" .env.example
grep -q "AGY" docker/install-extra-agents.sh
grep -q "antigravity" docker/install-extra-agents.sh
grep -q "127.0.0.1:3001:3001" compose.yaml
grep -q "./workspace/synthetic-only:/workspace" compose.yaml
grep -q "./config/antigravity" compose.yaml
grep -q "bypassPermissions" .env.example
grep -q "outbound" compose.ssh.yaml
grep -q "AGY" README.md
grep -q "https://antigravity.google/cli/install.sh" .env.example
grep -q "https://antigravity.google/docs/cli-using" README.md
grep -q "rock-r-library" README.md
grep -q "shinytest2" README.md

echo "scaffold check passed"
