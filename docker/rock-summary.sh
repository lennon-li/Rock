#!/usr/bin/env bash
# Prints a post-session summary: proposed outputs, scratch contents, workspace git status.
# Usage: rock-summary

WORKSPACE="${ROCK_WORKSPACE:-/workspace}"

echo "=== Rock Session Summary ==="

echo ""
echo "--- /work/proposed ---"
if [ -d /work/proposed ] && [ -n "$(ls -A /work/proposed 2>/dev/null)" ]; then
    ls -lah /work/proposed/
else
    echo "(empty)"
fi

echo ""
echo "--- /work/scratch ---"
if [ -d /work/scratch ] && [ -n "$(ls -A /work/scratch 2>/dev/null)" ]; then
    ls -lah /work/scratch/
else
    echo "(empty)"
fi

echo ""
echo "--- /workspace ---"
if git -C "$WORKSPACE" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$WORKSPACE" status --short
    git -C "$WORKSPACE" diff --stat HEAD 2>/dev/null || true
else
    echo "(not a git repo)"
    if [ -n "$(ls -A "$WORKSPACE" 2>/dev/null)" ]; then
        ls -lah "$WORKSPACE"/
    else
        echo "(empty)"
    fi
fi

echo ""
echo "=== End of Summary ==="
