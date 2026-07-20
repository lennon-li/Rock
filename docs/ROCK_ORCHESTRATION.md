# Rock Orchestration Workflow

## Purpose

Rock provides the isolated workstation. This workflow provides a Markdown control plane for a Hermes-supervised implementation and verification loop.

```text
User-approved goal and dispatch scope
  -> Hermes prepares bounded packets
  -> worker agent implements
  -> Hermes independently re-verifies
  -> reviewer agent audits when useful
  -> Hermes accepts, revises, blocks, or returns a human gate
  -> human owns commit, push, release, and deployment
```

This workflow follows the canonical Obsidian policies `DELEGATION.md`, `COMPLETION_REPORTING.md`, and the packet skill. Rock does not weaken those policies.

## Non-negotiable gates

- Hermes/Remy is the only project-governor delegator.
- Workers do not delegate to other workers.
- Hermes may draft packets without approval, but must not launch a state-changing worker until Lennon gives explicit approval for that specific dispatch.
- A single bounded local read-only inspection may use the existing policy exception: one invocation, no loop, no chained dispatch.
- Authorization is exactly one of:
  - `Authorization: READ-ONLY`
  - `Authorization: MAY MODIFY FILES WITHIN SCOPE`
- Missing authorization means read-only.
- Scope expansion, commit, push, delete, install, network writes, secrets, cloud/config changes, release, and deployment require separate explicit approval.
- Subagent output is unverified until Hermes reruns the decisive checks and audits scope.

## What is automated

After Lennon approves a specific implementation packet, Hermes may run the complete bounded task without pausing for ordinary reads, edits, and development commands already authorized by that packet. Hermes may perform the implementation-review-revision loop within the approved scope, provided no new gated action is introduced.

A retry is not permission to expand scope. Every retry must remain inside the original allowed paths, actions, resource permissions, and stop conditions.

## Run directory

Each approved goal gets a run directory:

```text
/work/proposed/runs/<run-id>/
  GOAL.md
  PLAN.md
  STATUS.md
  DECISIONS.md
  packets/
    T001.md
  reports/
    T001-attempt-1.md
  reviews/
    T001-review-1.md
  evidence/
    T001-tests-attempt-1.txt
    T001-attempt-1.patch
  FINAL.md
```

Use a run ID such as `2026-07-20-package-tests`.

## Lifecycle

```text
DRAFTED -> AWAITING_DISPATCH_APPROVAL -> APPROVED -> EXECUTING -> REVERIFYING ->
  ACCEPTED | REVISION_APPROVAL_REQUIRED | BLOCKED | HUMAN_REVIEW
```

A revision may execute without a new dispatch approval only when it stays wholly within the originally approved packet. Any scope or permission change returns to `AWAITING_DISPATCH_APPROVAL`.

## 1. Intake and preflight

Hermes:

1. runs `rock-preflight`,
2. identifies the project, platform, target agent/tool, repo root, base branch, and exact short SHA,
3. confirms the workspace is disposable, synthetic, backed up, or read-only as configured,
4. checks branch freshness before implementation work,
5. writes `GOAL.md` with the objective, constraints, definition of done, forbidden actions, and human gates.

For branch work, check:

```bash
git fetch
git log --oneline -1
git rev-list --count <branch>..main
```

Reconcile first when the branch is materially stale under the canonical delegation policy.

## 2. Planning and packet creation

Hermes writes `PLAN.md` and one packet per bounded task using `config/workflows/TASK_PACKET_TEMPLATE.md`.

Every implementation packet must include:

- From and To,
- base branch and exact SHA,
- memory commit when memory was used,
- authorization,
- project, platform, and target,
- allowed and forbidden paths,
- allowed actions and resource permissions,
- exact required checks and expected outcomes,
- mandatory out-of-scope handling,
- stop conditions,
- acceptance criteria,
- report-back requirements.

The packet must be self-contained enough for a fire-and-forget worker to succeed or stop cleanly without live questions.

## 3. Dispatch gate

Hermes presents the exact packet and asks Lennon for per-call approval.

No state-changing worker is launched before approval. Approval applies only to the named target, packet, authorization, scope, actions, and stop conditions.

The bounded read-only exception permits one local inspection without approval, but it may not loop or trigger a second agent automatically.

## 4. Worker execution

The worker receives:

1. `config/agents/WORKER.md`,
2. exactly one approved task packet,
3. only the context needed for that task.

Workers may edit and test only within the authorized scope. They must not sub-delegate, commit, push, delete, install, use unapproved network access, or alter other paths.

If an out-of-scope issue is discovered, the worker records it and continues within scope, or halts when the task cannot proceed. It must not fix the unrelated issue or wait for a live answer.

## 5. Required worker evidence

A worker report must include:

- files inspected and changed,
- commands executed with actual outputs or captured evidence paths,
- verification per acceptance item, tagged as `unit test`, `CI`, `executed locally`, `rendered walkthrough`, or `NOT verified`,
- `git status --short`,
- `git diff --stat`,
- final allowed-path scope audit,
- deviations and unresolved risks,
- patch or diff when relevant.

"Tests pass" is not equivalent to "feature validated." Claims without evidence remain unverified.

## 6. Hermes re-verification

Hermes does not accept the worker's completion claim directly. Hermes must:

1. inspect every changed path against the packet allowlist,
2. rerun decisive functional checks,
3. verify git status and absence of stray files,
4. distinguish test success from feature or rendered-output validation,
5. load R or UI verification policies when applicable,
6. tag every acceptance item with its verification method.

A scope violation is a packet-compliance failure even when the extra change appears useful.

## 7. Independent review

For multi-file, architectural, statistical, security-sensitive, or otherwise material work, Hermes routes the evidence to a different reviewer using `config/agents/REVIEWER.md`.

The reviewer is read-only and returns one verdict:

```text
ACCEPT
REVISE_WITHIN_SCOPE
BLOCK
HUMAN_REVIEW
```

The reviewer does not edit implementation files while acting as reviewer.

## 8. Revision loop

For `REVISE_WITHIN_SCOPE`, Hermes writes precise findings into the same packet's revision section and may dispatch another attempt only when the original approval already covers:

- the same target or an explicitly approved replacement,
- the same allowed paths,
- the same actions and resources,
- the same stop conditions.

Otherwise Hermes requests a new dispatch approval.

Default limit: three implementation attempts. Each retry must use materially improved instructions. At the limit, mark the task `BLOCKED` or `HUMAN_REVIEW`.

## 9. Integration and human gate

After all tasks are accepted, Hermes:

- runs project-level validation,
- checks the combined diff and scope,
- runs `rock-summary`,
- confirms TODO/status reconciliation,
- writes `FINAL.md` using `config/workflows/FINAL_TEMPLATE.md`.

Hermes completes all headless verification before involving Lennon. The remaining human gate must be concrete and normally completable in under one minute, such as inspecting a rendered artifact or deciding a specific tradeoff.

The human alone applies accepted work to the canonical repository and performs commit, push, release, or deployment after separate approval.

## Minimal user command

```text
Start Rock for <repo>. Draft a packet for this goal: <objective>.
```

Hermes prepares the run and packet, then stops at the dispatch gate. After Lennon approves the exact packet, Hermes executes, re-verifies, loops within scope, and returns the final review package.
