# Rock Orchestration Workflow

## Purpose

Rock provides the isolated workstation. This workflow provides the autonomous execution loop.

```text
User goal
  -> Hermes supervises
  -> worker agent implements
  -> reviewer agent validates
  -> Hermes accepts, retries, or escalates
  -> human approves publication
```

The workflow is model-agnostic. Hermes may delegate to Claude Code, Codex, Gemini CLI, OpenCode, AGY, or another available agent.

## Design principles

1. **One supervisor:** Hermes owns task state and completion decisions.
2. **Small delegated jobs:** workers receive bounded tasks with explicit acceptance criteria.
3. **Evidence over claims:** completion requires commands, results, diffs, and artifacts.
4. **Independent review:** the implementing worker does not approve its own work.
5. **Bounded loops:** retries are limited; repeated failure escalates to the human.
6. **Human publishing boundary:** agents do not commit, push, release, or deploy.
7. **Markdown control plane:** task state is stored as readable files, not hidden in chat history.

## Run directory

Each goal gets a run directory:

```text
/work/proposed/runs/<run-id>/
  GOAL.md
  PLAN.md
  STATUS.md
  DECISIONS.md
  tasks/
    T001.md
    T002.md
  reviews/
    T001-review.md
  evidence/
    T001-tests.txt
    T001-diff.patch
  FINAL.md
```

Use a run ID such as `2026-07-20-package-tests`.

## Lifecycle

```text
INTAKE -> PLANNED -> EXECUTING -> REVIEWING ->
  ACCEPTED | RETRYING | BLOCKED | HUMAN_REVIEW
```

### 1. Intake

Hermes creates `GOAL.md` from the user's request. It must state:

- objective,
- repository or workspace,
- constraints,
- definition of done,
- forbidden actions,
- human checkpoints.

Hermes runs `rock-preflight` before delegation.

### 2. Planning

Hermes inspects the repository using token-efficient tools and writes `PLAN.md`.

A plan should contain the smallest independent tasks that can be reviewed separately. Each task receives a `tasks/T###.md` file based on `config/workflows/TASK_TEMPLATE.md`.

Hermes selects an agent for each task based on task needs, not agent availability alone.

### 3. Delegation

Hermes starts a worker with:

1. `config/agents/WORKER.md`,
2. the relevant task file,
3. only the project context needed for that task.

Workers may edit a disposable clone and run tools. Workers must write outputs to the run directory and may not mark their own task accepted.

### 4. Evidence collection

A worker is finished only when it provides:

- changed-file list,
- patch or diff,
- commands executed,
- test/check outputs,
- unresolved risks,
- a completion recommendation.

A verbal statement such as "tests pass" is insufficient without the command and result.

### 5. Independent review

Hermes delegates review to a different agent using `config/agents/REVIEWER.md`.

The reviewer checks:

- task acceptance criteria,
- relevant tests and static checks,
- scope control,
- regressions and security risks,
- documentation and TODO closure,
- consistency between claimed and actual changes.

The reviewer writes `reviews/T###-review.md` with one verdict:

```text
ACCEPT
REVISE
BLOCK
HUMAN_REVIEW
```

### 6. Retry loop

For `REVISE`, Hermes updates the same task file with review findings and delegates another attempt.

Default limits:

- maximum implementation attempts per task: 3,
- maximum review cycles per task: 3,
- no repeated attempt with an unchanged instruction,
- after the limit: mark `BLOCKED` or `HUMAN_REVIEW`.

Hermes records retry reasons in `DECISIONS.md`.

### 7. Integration review

After all tasks are accepted, Hermes performs a whole-goal review:

- run the project-level validation suite,
- inspect combined diff,
- confirm tasks did not conflict,
- verify documentation and status files,
- run `rock-summary`.

Hermes writes `FINAL.md` using `config/workflows/FINAL_TEMPLATE.md`.

### 8. Human gate

Hermes presents:

- what changed,
- acceptance evidence,
- remaining risks,
- files ready for review,
- suggested commit message.

The human reviews, applies accepted patches to the canonical repository, commits, pushes, releases, or deploys outside Rock.

## Agent selection guidance

| Work type | Preferred worker characteristic |
|---|---|
| Broad repository analysis | strong context handling and planning |
| Focused implementation | precise code editing and test iteration |
| Large mechanical refactor | fast repository-wide editing |
| R/statistical validation | strong R and statistical reasoning |
| Independent review | different model or agent from implementer |
| Cheap first-pass inspection | local model when capability is sufficient |

Hermes should use the least expensive capable agent, but never reduce validation requirements.

## Stop conditions

Hermes must stop and request human review when:

- requirements are materially ambiguous,
- the task requires secrets or restricted credentials,
- destructive or irreversible actions are required,
- acceptance criteria cannot be verified,
- the retry limit is reached,
- agents disagree on a material architectural or statistical decision,
- real or sensitive data appears unexpectedly.

## Minimal invocation

A user-facing command can remain simple:

```text
Start Rock for <repo>. Goal: <objective>.
```

Hermes then:

1. creates the run directory,
2. writes the goal and plan,
3. delegates tasks,
4. reviews evidence,
5. loops within limits,
6. returns the final review package.
