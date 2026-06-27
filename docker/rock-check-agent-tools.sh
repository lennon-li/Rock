#!/usr/bin/env bash
set -Eeuo pipefail

# rock-check-agent-tools
# Verifies the presence and versions of agent efficiency and token-saving tools.

echo "================================================================="
echo "               Rock Agent Tools Verification                     "
echo "================================================================="

REQUIRED_TOOLS=(
  rg fd bat fzf jq yq tree git delta hyperfine duckdb just direnv
  ast-grep rga dust eza difft gh uv nox tox Rscript quarto node npm repomix code2prompt
)

missing=0
installed=0

for tool in "${REQUIRED_TOOLS[@]}"; do
  if command -v "$tool" >/dev/null 2>&1; then
    # Try to get version if possible
    version=""
    if [ "$tool" = "git" ]; then
      version="$(git --version | head -n1)"
    elif [ "$tool" = "node" ]; then
      version="node $(node --version)"
    elif [ "$tool" = "npm" ]; then
      version="npm $(npm --version)"
    elif [ "$tool" = "Rscript" ]; then
      version="Rscript $(Rscript --version 2>&1 | head -n1)"
    elif [ "$tool" = "quarto" ]; then
      version="quarto $(quarto --version)"
    elif [ "$tool" = "uv" ]; then
      version="$(uv --version | head -n1)"
    elif [ "$tool" = "rg" ]; then
      version="$(rg --version | head -n1)"
    elif [ "$tool" = "fd" ]; then
      version="$(fd --version | head -n1)"
    elif [ "$tool" = "bat" ]; then
      version="$(bat --version | head -n1)"
    elif [ "$tool" = "jq" ]; then
      version="$(jq --version | head -n1)"
    elif [ "$tool" = "yq" ]; then
      version="$(yq --version | head -n1)"
    elif [ "$tool" = "duckdb" ]; then
      version="duckdb $(duckdb --version | head -n1)"
    elif [ "$tool" = "ast-grep" ]; then
      version="$(ast-grep --version | head -n1)"
    elif [ "$tool" = "just" ]; then
      version="$(just --version | head -n1)"
    elif [ "$tool" = "delta" ]; then
      version="$(delta --version | head -n1)"
    elif [ "$tool" = "repomix" ]; then
      version="repomix $(repomix --version | head -n1)"
    elif [ "$tool" = "code2prompt" ]; then
      version="code2prompt $(code2prompt --version 2>&1 | head -n1)"
    else
      version="OK ($(command -v "$tool"))"
    fi
    printf "  %-14s [OK]      %s\n" "$tool" "$version"
    installed=$((installed + 1))
  else
    printf "  %-14s [MISSING]\n" "$tool"
    missing=$((missing + 1))
  fi
done

echo "================================================================="
echo "Summary: $installed tools installed, $missing tools missing."
echo "================================================================="

if [ "$missing" -gt 0 ]; then
  exit 1
else
  exit 0
fi
