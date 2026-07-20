# Local LLM access

Rock can connect to any OpenAI-compatible local or private model server without bundling the model runtime into the Docker image.

See [`docs/LOCAL_LLM_GUIDE.md`](docs/LOCAL_LLM_GUIDE.md) for setup instructions covering llama.cpp, Ollama, LM Studio, vLLM, SSH tunnels, Docker Desktop, native Linux Docker, and WSL 2.

After configuration:

```bash
docker compose exec rock rock-local-llm-check
docker compose exec rock rock-local-llm "Explain this R function."
```
