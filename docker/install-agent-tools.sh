#!/usr/bin/env bash
set -Eeuo pipefail

# This script installs/updates all required agent efficiency tools for Rock.
# It runs during docker build as root, and is also usable at runtime.
# It is fully idempotent and verifies presence before downloading/installing.

echo "==> Starting Agent Tools Installation..."

# 1. System packages via apt
echo "--> Installing apt packages..."
apt-get update
apt-get install -y --no-install-recommends \
    git \
    ripgrep \
    fd-find \
    bat \
    fzf \
    jq \
    tree \
    direnv \
    hyperfine \
    unzip \
    curl \
    wget \
    ca-certificates

# Setup Debian-specific symlinks
echo "--> Setting up symlinks for fd and bat..."
ln -sf /usr/bin/fdfind /usr/local/bin/fd
ln -sf /usr/bin/batcat /usr/local/bin/bat

# 2. Download prebuilt binaries to /usr/local/bin
if ! command -v yq >/dev/null 2>&1; then
  echo "--> Downloading yq..."
  wget -q https://github.com/mikefarah/yq/releases/download/v4.44.1/yq_linux_amd64 -O /usr/local/bin/yq
  chmod +x /usr/local/bin/yq
else
  echo "--> yq already installed."
fi

if ! command -v just >/dev/null 2>&1; then
  echo "--> Downloading just..."
  curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to /usr/local/bin
else
  echo "--> just already installed."
fi

if ! command -v duckdb >/dev/null 2>&1; then
  echo "--> Downloading DuckDB..."
  wget -qO /tmp/duckdb.zip https://github.com/duckdb/duckdb/releases/download/v1.0.0/duckdb_cli-linux-amd64.zip
  unzip -o -d /usr/local/bin /tmp/duckdb.zip
  chmod +x /usr/local/bin/duckdb
  rm -f /tmp/duckdb.zip
else
  echo "--> duckdb already installed."
fi

if ! command -v ast-grep >/dev/null 2>&1; then
  echo "--> Downloading ast-grep..."
  wget -qO /tmp/ast-grep.zip https://github.com/ast-grep/ast-grep/releases/download/0.44.0/app-x86_64-unknown-linux-gnu.zip
  unzip -o -d /usr/local/bin /tmp/ast-grep.zip
  chmod +x /usr/local/bin/ast-grep /usr/local/bin/sg
  rm -f /tmp/ast-grep.zip
else
  echo "--> ast-grep already installed."
fi

if ! command -v rga >/dev/null 2>&1; then
  echo "--> Downloading ripgrep_all (rga)..."
  wget -qO- https://github.com/phiresky/ripgrep_all/releases/download/v0.9.6/ripgrep_all-v0.9.6-x86_64-unknown-linux-musl.tar.gz | tar -xz -C /tmp
  mv -f /tmp/ripgrep_all-v0.9.6-x86_64-unknown-linux-musl/rga* /usr/local/bin/
  rm -rf /tmp/ripgrep_all-v0.9.6-x86_64-unknown-linux-musl
else
  echo "--> rga already installed."
fi

if ! command -v dust >/dev/null 2>&1; then
  echo "--> Downloading dust..."
  wget -qO- https://github.com/bootandy/dust/releases/download/v1.1.1/dust-v1.1.1-x86_64-unknown-linux-gnu.tar.gz | tar -xz -C /tmp
  mv -f /tmp/dust-v1.1.1-x86_64-unknown-linux-gnu/dust /usr/local/bin/
  rm -rf /tmp/dust-v1.1.1-x86_64-unknown-linux-gnu
else
  echo "--> dust already installed."
fi

if ! command -v eza >/dev/null 2>&1; then
  echo "--> Downloading eza..."
  wget -qO- https://github.com/eza-community/eza/releases/download/v0.18.20/eza_x86_64-unknown-linux-gnu.tar.gz | tar -xz -C /usr/local/bin
  chmod +x /usr/local/bin/eza
else
  echo "--> eza already installed."
fi

if ! command -v difft >/dev/null 2>&1; then
  echo "--> Downloading difftastic..."
  wget -qO- https://github.com/Wilfred/difftastic/releases/download/0.60.0/difft-x86_64-unknown-linux-gnu.tar.gz | tar -xz -C /usr/local/bin
  chmod +x /usr/local/bin/difft
else
  echo "--> difft already installed."
fi

if ! command -v delta >/dev/null 2>&1; then
  echo "--> Downloading git-delta..."
  wget -qO- https://github.com/dandavison/delta/releases/download/0.18.2/delta-0.18.2-x86_64-unknown-linux-gnu.tar.gz | tar -xz -C /tmp
  mv -f /tmp/delta-0.18.2-x86_64-unknown-linux-gnu/delta /usr/local/bin/
  rm -rf /tmp/delta-0.18.2-x86_64-unknown-linux-gnu
else
  echo "--> delta already installed."
fi

if ! command -v uv >/dev/null 2>&1; then
  echo "--> Downloading uv..."
  wget -qO- https://github.com/astral-sh/uv/releases/download/0.2.22/uv-x86_64-unknown-linux-gnu.tar.gz | tar -xz -C /tmp
  mv -f /tmp/uv-x86_64-unknown-linux-gnu/uv* /usr/local/bin/
  rm -rf /tmp/uv-x86_64-unknown-linux-gnu
else
  echo "--> uv already installed."
fi

if ! command -v quarto >/dev/null 2>&1; then
  echo "--> Installing Quarto..."
  wget -q https://github.com/quarto-dev/quarto-cli/releases/download/v1.4.557/quarto-1.4.557-linux-amd64.deb -O /tmp/quarto.deb
  dpkg -i /tmp/quarto.deb
  rm -f /tmp/quarto.deb
else
  echo "--> Quarto already installed."
fi

# 3. Python tools
if ! command -v nox >/dev/null 2>&1 || ! command -v tox >/dev/null 2>&1; then
  echo "--> Installing Python packages nox and tox..."
  pip3 install --break-system-packages nox tox
else
  echo "--> nox and tox already installed."
fi

# 4. Node & CLI tools
mkdir -p /home/claude/.local
export NPM_CONFIG_PREFIX=/home/claude/.local

if ! command -v repomix >/dev/null 2>&1; then
  echo "--> Installing global Node tools (repomix)..."
  npm install -g --unsafe-perm repomix
else
  echo "--> repomix already installed."
fi

if ! command -v code2prompt >/dev/null 2>&1; then
  echo "--> Installing code2prompt via pip3..."
  pip3 install --break-system-packages code2prompt
else
  echo "--> code2prompt already installed."
fi

# Clean up apt caches
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "==> Agent Tools Installation Completed Successfully!"
