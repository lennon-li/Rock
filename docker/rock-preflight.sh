#!/usr/bin/env bash
# Scans /workspace for files that should not be exposed to agents.
# Warns on suspicious findings. Exits 1 in strict mode if any warnings found.
# Usage: rock-preflight
#        ROCK_PREFLIGHT_STRICT=1 rock-preflight   # exit 1 on any warning

set -uo pipefail

WORKSPACE="${ROCK_WORKSPACE:-/workspace}"
STRICT="${ROCK_PREFLIGHT_STRICT:-0}"
WARNINGS=0

warn() {
    echo "ROCK PREFLIGHT WARNING: $1" >&2
    WARNINGS=$((WARNINGS + 1))
}

if [ ! -d "$WORKSPACE" ]; then
    echo "ROCK PREFLIGHT: workspace $WORKSPACE not found — skipping." >&2
    exit 0
fi

# .env files (exclude .env.example / .env.sample / .env.template)
while IFS= read -r -d '' f; do
    base="$(basename "$f")"
    case "$base" in
        .env.example|.env.sample|.env.template|.env.dist) ;;
        *) warn "Possible secrets file: $f" ;;
    esac
done < <(find "$WORKSPACE" \( -name '.env' -o -name '.env.*' \) -print0 2>/dev/null | sort -z)

# SSH private key filenames
while IFS= read -r -d '' f; do
    warn "Possible SSH private key: $f"
done < <(find "$WORKSPACE" \
    \( -name 'id_rsa' \
    -o -name 'id_ed25519' \
    -o -name 'id_dsa' \
    -o -name 'id_ecdsa' \
    -o -name '*.pem' \) \
    -print0 2>/dev/null)

# Hidden auth directories
for authdir in .ssh .gnupg .aws .gcloud .azure; do
    if [ -d "$WORKSPACE/$authdir" ]; then
        warn "Auth directory present in workspace: $WORKSPACE/$authdir"
    fi
done

# Cloud credential files
while IFS= read -r -d '' f; do
    warn "Possible cloud credentials: $f"
done < <(find "$WORKSPACE" \
    \( -name 'credentials' \
    -o -name 'credentials.json' \
    -o -name 'service-account*.json' \
    -o -name '*-key.json' \
    -o -name '*.p12' \
    -o -name '*.pfx' \) \
    -print0 2>/dev/null)

# Large files (>100 MB)
while IFS= read -r -d '' f; do
    warn "Large file (>100 MB): $f"
done < <(find "$WORKSPACE" -size +100M -print0 2>/dev/null)

# Production-looking config names
while IFS= read -r -d '' f; do
    warn "Production-looking config: $f"
done < <(find "$WORKSPACE" \
    \( -name 'prod.env' \
    -o -name 'production.env' \
    -o -name 'prod.yml' \
    -o -name 'production.yml' \
    -o -name 'prod.yaml' \
    -o -name 'production.yaml' \) \
    -print0 2>/dev/null)

echo "" >&2
if [ "$WARNINGS" -gt 0 ]; then
    echo "ROCK PREFLIGHT: $WARNINGS warning(s) found in $WORKSPACE." >&2
    echo "ROCK PREFLIGHT: Review the workspace before running agents." >&2
    if [ "$STRICT" = "1" ]; then
        echo "ROCK PREFLIGHT: Strict mode — blocking." >&2
        exit 1
    fi
    exit 0
fi

echo "ROCK PREFLIGHT: Workspace looks clean." >&2
exit 0
