# Connect Rock to a Local LLM

Rock can call any model server that provides an OpenAI-compatible API. The model runtime stays outside the Rock image; Rock only connects to its HTTP endpoint.

Supported examples include:

- llama.cpp `llama-server`
- Ollama through an OpenAI-compatible endpoint
- LM Studio
- vLLM
- LocalAI
- an SSH-forwarded private or remote model server

## How the connection works

```text
Model server or SSH tunnel on the host
        -> http://localhost:<port>/v1
        -> host.docker.internal:<port>
        -> Rock container
```

Inside a container, `localhost` means the container itself. Therefore, when the server runs on the Docker host, configure Rock with `host.docker.internal`.

## 1. Confirm the model server is OpenAI-compatible

From the host, verify the models endpoint. Replace the port if needed:

```bash
curl -fsS http://localhost:8080/v1/models
```

The response should be JSON containing a model list. If this fails, fix the model server or tunnel before configuring Rock.

## 2. Configure Rock

Copy the example environment file if you have not already done so:

```bash
cp .env.example .env
```

Set these values in `.env`:

```env
ROCK_LOCAL_LLM_BASE_URL=http://host.docker.internal:8080/v1
ROCK_LOCAL_LLM_API_KEY=not-needed
ROCK_LOCAL_LLM_MODEL=local-model
ROCK_LOCAL_LLM_MAX_TOKENS=4096
ROCK_LOCAL_LLM_TEMPERATURE=0.2
ROCK_LOCAL_LLM_TIMEOUT_SECONDS=120
```

Use the model id reported by `/v1/models` when the server requires an exact id. Some single-model llama.cpp servers accept any model string.

Do not put a real API key in a committed file. `.env` should remain local and untracked.

## 3. Rebuild and restart Rock

The helper commands are installed into the image, so rebuild after upgrading Rock:

```bash
docker compose build
docker compose up -d
```

When only `.env` values change, recreation is sufficient:

```bash
docker compose up -d --force-recreate
```

## 4. Test from inside Rock

Check connectivity and display the model inventory:

```bash
docker compose exec rock rock-local-llm-check
```

Send a prompt:

```bash
docker compose exec rock rock-local-llm "Explain what head() does in R."
```

Pipe a longer prompt or task packet through standard input:

```bash
cat task.md | docker compose exec -T rock rock-local-llm
```

The helper calls `/v1/chat/completions` and prints the first assistant message.

## Platform notes

### Docker Desktop on Windows or macOS

`host.docker.internal` is normally available automatically. Ensure the model server accepts connections through the host interface used by Docker Desktop.

A server listening only on the host's loopback interface may still work with Docker Desktop, depending on the runtime. If it does not, configure the model server to listen on an appropriate host interface and protect it with local firewall rules.

### Native Docker Engine on Linux

Rock's `compose.yaml` maps:

```yaml
extra_hosts:
  - "host.docker.internal:host-gateway"
```

This gives Linux containers the same hostname. The model server must listen on an address reachable through the Docker host gateway; a server bound only to `127.0.0.1` may not be reachable.

Prefer binding to the Docker-facing host address. Binding to `0.0.0.0` is broader and should be protected by firewall rules. Never expose an unauthenticated model endpoint publicly.

### WSL 2

The result depends on where Docker and the model server run:

- Docker Desktop plus a Windows-hosted server: use `host.docker.internal`.
- Native Docker inside WSL plus a WSL-hosted server: ensure the server listens on the WSL/Docker-reachable interface.
- A server on another machine: use its private hostname or IP if routing and firewall rules allow it.

Always test from inside Rock with `rock-local-llm-check`; a successful host-side curl does not prove container connectivity.

## SSH-forwarded private model

When a model is reachable only through SSH, create the tunnel on the Docker host. Example:

```bash
ssh -N -L 8080:private-model-host:8080 gateway-host
```

Verify on the host:

```bash
curl -fsS http://localhost:8080/v1/models
```

Then configure Rock:

```env
ROCK_LOCAL_LLM_BASE_URL=http://host.docker.internal:8080/v1
```

Keep the tunnel running while Rock uses the model.

## Provider examples

### llama.cpp

Start an OpenAI-compatible server, choosing a bind address appropriate for your platform:

```bash
llama-server -m /path/to/model.gguf --host 0.0.0.0 --port 8080
```

Then use:

```env
ROCK_LOCAL_LLM_BASE_URL=http://host.docker.internal:8080/v1
```

Do not use `0.0.0.0` without firewall protection.

### LM Studio

Enable LM Studio's local server and note its port, commonly `1234`:

```env
ROCK_LOCAL_LLM_BASE_URL=http://host.docker.internal:1234/v1
ROCK_LOCAL_LLM_MODEL=<model-id-shown-by-/v1/models>
```

### Ollama

Use Ollama's OpenAI-compatible API, commonly on port `11434`:

```env
ROCK_LOCAL_LLM_BASE_URL=http://host.docker.internal:11434/v1
ROCK_LOCAL_LLM_MODEL=<ollama-model-name>
```

Ollama may need its host binding configured so Docker can reach it.

### vLLM

For a vLLM OpenAI-compatible server on port `8000`:

```env
ROCK_LOCAL_LLM_BASE_URL=http://host.docker.internal:8000/v1
ROCK_LOCAL_LLM_MODEL=<served-model-name>
```

## Direct use by agents and programs

The environment variables are available to all processes in Rock:

```text
ROCK_LOCAL_LLM_BASE_URL
ROCK_LOCAL_LLM_API_KEY
ROCK_LOCAL_LLM_MODEL
ROCK_LOCAL_LLM_MAX_TOKENS
ROCK_LOCAL_LLM_TEMPERATURE
ROCK_LOCAL_LLM_TIMEOUT_SECONDS
```

Agents can invoke the model through `rock-local-llm`, while R, Python, shell scripts, or other clients can call the endpoint directly.

Treat local-model output as unverified worker output. For code changes, require bounded scope, exact validation commands, and independent review before acceptance.

## Troubleshooting

### `ROCK_LOCAL_LLM_BASE_URL is not configured`

Set the value in `.env` and recreate the container:

```bash
docker compose up -d --force-recreate
```

### Host curl works but Rock cannot connect

Test name resolution and the endpoint inside Rock:

```bash
docker compose exec rock getent hosts host.docker.internal
docker compose exec rock curl -v http://host.docker.internal:8080/v1/models
```

Common causes are:

- the model server listens only on an unreachable loopback interface;
- the wrong port is configured;
- a host firewall blocks Docker traffic;
- an SSH tunnel is not running;
- the server is not actually OpenAI-compatible.

### `401 Unauthorized`

Set the endpoint's required token:

```env
ROCK_LOCAL_LLM_API_KEY=<token>
```

### Model not found

Run:

```bash
docker compose exec rock rock-local-llm-check
```

Copy the reported model id into `ROCK_LOCAL_LLM_MODEL`.

### Request times out

Increase:

```env
ROCK_LOCAL_LLM_TIMEOUT_SECONDS=300
```

Also reduce prompt size or output-token limits for slower hardware.

## Security rules

- Keep model endpoints on loopback, a Docker-facing interface, or a trusted private network.
- Do not publicly expose an unauthenticated inference server.
- Do not pass secrets, credentials, or sensitive data to a model unless the user explicitly authorizes it.
- A local model is a worker, not a trusted reviewer or publication authority.
