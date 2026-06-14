#!/usr/bin/env bash
set -euo pipefail

# Runtime helper for fast-moving agent CLIs.
# Run inside the Rock container when you want latest CLI tools without editing the image.

AGY_INSTALL_COMMAND_DEFAULT="curl -fsSL https://antigravity.google/cli/install.sh | bash"
AGY_INSTALL_COMMAND="${ROCK_AGY_INSTALL_COMMAND:-$AGY_INSTALL_COMMAND_DEFAULT}"
UPDATE_AGY="${ROCK_UPDATE_AGY:-1}"
NPM_PACKAGES_DEFAULT="@openai/codex@latest @anthropic-ai/claude-code@latest @google/gemini-cli@latest opencode-ai@latest"
NPM_PACKAGES="${ROCK_UPDATE_NPM_PACKAGES:-$NPM_PACKAGES_DEFAULT}"

print_version() {
  local cmd="$1"
  if command -v "$cmd" >/dev/null 2>&1; then
    printf '\n--- %s ---\n' "$cmd"
    "$cmd" --version 2>/dev/null || "$cmd" version 2>/dev/null || true
  fi
}

if [[ "$UPDATE_AGY" == "1" ]]; then
  echo "Updating/installing AGY / Antigravity CLI from official installer"
  bash -lc "$AGY_INSTALL_COMMAND" || echo "WARNING: AGY update failed; continuing with npm updates." >&2
else
  echo "Skipping AGY update because ROCK_UPDATE_AGY=$UPDATE_AGY"
fi

if [[ -n "$NPM_PACKAGES" && "$NPM_PACKAGES" != "0" && "$NPM_PACKAGES" != "none" ]]; then
  if ! command -v npm >/dev/null 2>&1; then
    echo "ROCK_UPDATE_NPM_PACKAGES was set, but npm is not available." >&2
    exit 1
  fi

  echo "Updating npm-based agent CLIs: $NPM_PACKAGES"
  # shellcheck disable=SC2086
  npm install -g $NPM_PACKAGES
fi

for cmd in agy codex claude gemini opencode; do
  print_version "$cmd"
done

echo "Agent CLI update check complete"
