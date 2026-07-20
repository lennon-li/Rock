#!/usr/bin/env bash
set -euo pipefail

base_url="${ROCK_LOCAL_LLM_BASE_URL:-}"
api_key="${ROCK_LOCAL_LLM_API_KEY:-not-needed}"
timeout_seconds="${ROCK_LOCAL_LLM_TIMEOUT_SECONDS:-120}"

if [[ -z "$base_url" ]]; then
  echo "ROCK_LOCAL_LLM_BASE_URL is not configured." >&2
  echo "Set it in .env, for example:" >&2
  echo "  ROCK_LOCAL_LLM_BASE_URL=http://host.docker.internal:8080/v1" >&2
  exit 2
fi

base_url="${base_url%/}"
headers=(-H "Accept: application/json")
if [[ -n "$api_key" ]]; then
  headers+=(-H "Authorization: Bearer $api_key")
fi

echo "Checking local LLM endpoint: $base_url"
response="$(curl --fail --silent --show-error \
  --connect-timeout 10 \
  --max-time "$timeout_seconds" \
  "${headers[@]}" \
  "$base_url/models")"

if command -v jq >/dev/null 2>&1; then
  printf '%s\n' "$response" | jq .
else
  printf '%s\n' "$response"
fi

echo "Local LLM endpoint is reachable."
