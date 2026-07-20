# Task Packet: <T### - title>

From: Hermes / Remy (<platform>)
To: <worker persona and CLI> (<platform>)
Base: <branch> @ <short-sha> (verify with `git log --oneline -1`; STOP on mismatch)
Memory commit: <sha or N/A>

Authorization: <READ-ONLY | MAY MODIFY FILES WITHIN SCOPE>
Project: <project/repository>
Platform: <machine/container>
Target agent/tool: <persona / CLI / model>
Repo root: <path>

Allowed paths:
- <path>

Forbidden paths:
- `.git/**`
- <path>

Allowed actions:
- <action>

Resource permissions:
- Network: <DENIED or exact approved use>
- Installs/dependencies: <DENIED or exact approved use>
- Long-running jobs: <DENIED or limits>
- Secrets: DENIED unless separately approved

Required checks:
1. `<exact command>` -> expected: <outcome>
2. `git status --short`
3. `git diff --stat`
4. Compare all touched paths with Allowed paths and revert accidental out-of-scope changes before reporting.

Out-of-scope handling: If you notice something worth fixing outside Allowed paths - a bug, stray file, unrelated failure, or cleanup opportunity - do not touch it and do not wait for a live answer. Record it in the report. Continue within scope, or halt and report if this task cannot be completed without expanding scope.

Stop and report before:
- base mismatch,
- scope expansion,
- commit or push,
- delete,
- install or dependency change not explicitly approved above,
- network write not explicitly approved above,
- secrets,
- cloud/config change,
- release or deployment,
- destructive or irreversible action.

## Task

<bounded implementation or inspection objective>

## Acceptance criteria

- [ ] <observable criterion>
- [ ] <observable criterion>

Acceptance may also be a precise new boundary when completion is blocked, provided the boundary and evidence are reported accurately.

## Report back

Write to: `/work/proposed/runs/<run-id>/reports/<task>-attempt-<n>.md`

Include:

- base verification,
- files inspected and changed,
- commands with actual outputs or evidence paths,
- each acceptance item tagged `unit test`, `CI`, `executed locally`, `rendered walkthrough`, or `NOT verified`,
- final `git status --short`,
- final `git diff --stat`,
- scope self-audit,
- deviations, observations, and unresolved risks,
- patch/diff evidence path,
- recommendation: `IMPLEMENTED`, `PARTIAL`, or `BLOCKED`.

## Revision instructions

<empty on first attempt; Hermes adds precise reviewer findings here for an approved in-scope retry>
