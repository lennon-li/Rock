#!/usr/bin/env bash
set -euo pipefail

base_url="${ROCK_LOCAL_LLM_BASE_URL:-}"
api_key="${ROCK_LOCAL_LLM_API_KEY:-not-needed}"
model="${ROCK_LOCAL_LLM_MODEL:-local-model}"
max_tokens="${ROCK_LOCAL_LLM_MAX_TOKENS:-4096}"
temperature="${ROCK_LOCAL_LLM_TEMPERATURE:-0.2}"
timeout_seconds="${ROCK_LOCAL_LLM_TIMEOUT_SECONDS:-120}"

usage() {
  cat <<'EOF'
Usage:
  rock-local-llm "prompt text"
  printf 'prompt text' | rock-local-llm

Environment:
  ROCK_LOCAL_LLM_BASE_URL       Required OpenAI-compatible /v1 base URL
  ROCK_LOCAL_LLM_API_KEY        Optional bearer token; default: not-needed
  ROCK_LOCAL_LLM_MODEL          Model id; default: local-model
  ROCK_LOCAL_LLM_MAX_TOKENS     Maximum output tokens; default: 4096
  ROCK_LOCAL_LLM_TEMPERATURE    Sampling temperature; default: 0.2
  ROCK_LOCAL_LLM_TIMEOUT_SECONDS Request timeout; default: 120
EOF
}

if [[ -z "$base_url" ]]; then
  echo "ROCK_LOCAL_LLM_BASE_URL is not configured." >&2
  usage >&2
  exit 2
fi

if (($# > 0)); then
  prompt="$*"
elif [[ ! -t 0 ]]; then
  prompt="$(cat)"
else
  usage >&2
  exit 2
fi

if [[ -z "$prompt" ]]; then
  echo "Prompt is empty." >&2
  exit 2
fi

base_url="${base_url%/}"
headers=(-H "Content-Type: application/json")
if [[ -n "$api_key" ]]; then
  headers+=(-H "Authorization: Bearer $api_key")
fi

payload="$(jq -n \
  --arg model "$model" \
  --arg prompt "$prompt" \
  --argjson max_tokens "$max_tokens" \
  --argjson temperature "$temperature" \
  '{
    model: $model,
    messages: [{role: "user", content: $prompt}],
    max_tokens: $max_tokens,
    temperature: $temperature
  }')"

response="$(curl --fail --silent --show-error \
  --connect-timeout 10 \
  --max-time "$timeout_seconds" \
  "${headers[@]}" \
  -d "$payload" \
  "$base_url/chat/completions")"

content="$(printf '%s\n' "$response" | jq -r '.choices[0].message.content // empty')"
if [[ -z "$content" ]]; then
  echo "The endpoint returned no chat-completion content." >&2
  printf '%s\n' "$response" | jq . >&2 || printf '%s\n' "$response" >&2
  exit 1
fi

printf '%s\n' "$content"
