# TODO

## Install agent efficiency tools inside Rock

Goal: make Rock include the same agent efficiency and token-saving tool stack defined in the Obsidian repo, so Claude Code, Codex, Gemini CLI, OpenCode, and other agents can use these tools automatically inside the Rock container.

Reference source of truth:

- Obsidian repo: `lennon-li/obsidian`
- Installer: `tools/install-agent-tools.sh`
- Handoff: `tools/AGENT_TOOL_HANDOFF.md`

Agent instruction before implementation:

```bash
bash tools/install-agent-tools.sh --agent-rules
```

When implementing this in Rock, do **not** blindly reinstall tools that are already present in the image. First verify existing tools inside the running container:

```bash
docker compose exec rock bash -lc '
for t in rg fd bat fzf jq yq tree git delta hyperfine duckdb just direnv ast-grep rga dust eza difft gh uv nox tox Rscript quarto node npm repomix code2prompt; do
  if command -v "$t" >/dev/null 2>&1; then
    printf "%-14s OK      %s\n" "$t" "$(command -v "$t")"
  else
    printf "%-14s MISSING\n" "$t"
  fi
done
'
```

Target tool categories:

- Fast search: `rg`, `fd`, `git grep`, `rga`
- File inspection: `bat`, `jq`, `yq`, `duckdb`
- Structural/code search: `ast-grep`
- Repo packing/context: `repomix`, `code2prompt`
- Task running: `just`, `make`
- Diffs/review: `delta`, `difftastic`
- System/navigation: `tree`, `eza`, `dust`, `hyperfine`
- Python workflow: `uv`, `nox`, `tox`
- GitHub workflow: `gh`

Implementation options:

1. Add missing tools directly to the Rock `Dockerfile` / build scripts.
2. Add a Rock-specific bootstrap script such as `scripts/install-agent-tools.sh` that is safe to rerun.
3. Add a runtime helper command such as `rock-check-agent-tools` that reports installed/missing tools without installing anything.
4. Add a runtime helper command such as `rock-install-missing-agent-tools` that installs only missing tools.

Important constraints:

- Do not install Docker inside Rock. Rock already runs inside Docker.
- Do not install Google Cloud CLI by default; keep it opt-in if added.
- Do not reinstall tools already available in the image.
- Prefer image-level installation for stable tools so every agent session gets them.
- Keep runtime installation idempotent and verify-first.
- Keep agent instructions compact; agents should search before reading full files and should not dump whole repos into context.

Definition of done:

- [x] Rock image includes or can install the agent efficiency tool stack.
- [x] A check command confirms which tools are installed and which are missing.
- [x] Agents are instructed to use `rg`, `fd`, `bat`, `jq`, `yq`, `duckdb`, `ast-grep`, `rga`, `just`, `repomix`, and `code2prompt` for token-saving repo work.
- [x] README documents the check/install commands.
