# Rock Agent Access Model

## Purpose

Rock uses a two-zone permission model plus a human-owned publishing boundary.

```text
Container zone:
  Agents can use the container as a full development workstation.

Mapped-folder zone:
  Agents can read by default, but must ask before changing host-mapped files.

Publishing boundary:
  Humans commit and push. Agents do not.
```

This gives agents freedom inside the disposable environment while keeping host/project files and publication under human control.

## Core Rule

```text
Agents may freely operate inside container-owned paths.
Agents may read mapped host folders.
Agents must ask before modifying mapped host folders.
Agents must not commit or push to the canonical repository.
Humans review, commit, and push outside Docker.
```

## Recommended Default Workflow

The safest default is not to mount the real working repo directly.

Use an empty or disposable mapped folder as the agent workspace:

```text
Host canonical repo:
  stays outside Docker and is not mounted into Rock.

Docker mapped workspace:
  starts empty or disposable.

Agent:
  clones or pulls a fresh copy into the disposable workspace.
  works only on that copy.
  creates diff/patch/summary output.
  cannot push.

Human:
  reviews the output outside Docker.
  applies accepted changes to the real repo.
  commits and pushes manually.
```

This makes the agent workspace replaceable. If it becomes messy, delete it and clone again.

## Zone 1: Container-Owned System Zone

Agents should have broad access inside the container.

Allowed without repeated approval:

```text
- use installed shell and development tools
- install R packages into a container/user library
- install temporary development dependencies
- write scratch files
- create logs
- run tests and package checks
- build local artifacts
- modify container-owned working directories
- clone/pull repositories into disposable agent-work folders
- produce patch files and summaries
```

Typical container-owned paths:

```text
/tmp
/var/tmp
/home/claude
/work/scratch
/work/proposed
/home/claude/R/library
```

These paths are part of the container workspace or named Docker volumes. They are not treated as host project boundaries.

## Zone 2: Mapped Folder Zone

Mapped folders are host-controlled boundaries.

Examples:

```text
/workspace
/opt/rock/skills
/home/claude/.claude
/home/claude/.ssh
/mnt/project
/mnt/data
```

Default rule:

```text
Read is allowed.
Write requires permission.
Delete requires permission.
Move/rename requires permission.
Generating outputs into mapped folders requires permission.
```

## Zone 3: Human Publishing Boundary

Publishing is human-owned.

Agents should not perform these actions inside Docker:

```text
- git commit
- git push
- gh release
- package release
- deployment
- publishing generated artifacts to external services
```

The agent may prepare:

```text
- git diff output
- patch files
- changed-file summary
- test logs
- explanation of design choices
- suggested commit message
```

But the human performs:

```text
- final review
- applying accepted patches to the canonical repo
- git commit
- git push
- release/deploy decisions
```

This keeps the final irreversible or externally visible action outside the agent boundary.

## Technical Enforcement

Instruction alone is not enough. If Docker has GitHub credentials or push-capable SSH keys, the agent can technically push.

Therefore Rock should enforce the publishing boundary technically:

```text
- do not mount broad host ~/.ssh into Rock
- do not mount write-capable GitHub SSH keys by default
- do not provide GitHub tokens with repo write permission by default
- do not persist gh authentication in the default agent workspace
- prefer HTTPS clone without stored write credentials for disposable clones
- allow git fetch/pull/clone, but do not enable push credentials
```

If Docker mounts a folder as read-write, the agent can technically change it. Therefore, if Rock truly requires permission before mapped-folder changes, the default implementation should mount mapped folders read-only and give the agent a separate writable staging area.

Recommended structure:

```text
/workspace       mapped disposable workspace or read-only project folder
/work/proposed   writable proposed-change area
/work/scratch    writable experiment area
```

For the safest workflow, `/workspace` is an empty/disposable folder, not the canonical local repo.

## Recommended Compose Pattern

```yaml
services:
  rock:
    volumes:
      - ./workspace/agent-work:/workspace
      - rock-proposed:/work/proposed
      - rock-scratch:/work/scratch
      - rock-r-library:/home/claude/R/library
      - ./config/skills:/opt/rock/skills:ro

volumes:
  rock-proposed:
  rock-scratch:
  rock-r-library:
```

For read-only review mode:

```yaml
services:
  rock:
    volumes:
      - ./workspace/review-only:/workspace:ro
      - rock-proposed:/work/proposed
      - rock-scratch:/work/scratch
```

## Disposable Clone Workflow

When the agent needs to work on a repo:

```text
1. Start with an empty or disposable /workspace.
2. Clone or pull the target repo into /workspace/project-name.
3. Work only in that disposable clone.
4. Run tests and checks inside Docker.
5. Produce a patch, diff, and summary.
6. Do not commit.
7. Do not push.
8. Human reviews and applies accepted changes outside Docker.
```

Example inside Docker:

```bash
cd /workspace
git clone https://github.com/lennon-li/Rock.git rock-work
cd rock-work
# agent works here
git diff > /work/proposed/rock-agent.patch
git status > /work/proposed/rock-status.txt
```

The human can then review and apply the patch outside Docker.

## Change Workflow for Mapped Files

When the agent wants to change mapped files directly:

```text
1. Inspect files in /workspace.
2. Create edited copies or patch files in /work/proposed.
3. Summarize the intended changes.
4. Ask for permission.
5. Apply changes only after approval.
```

Direct mapped-folder edits should be treated as an approved edit session, not the default mode.

## R Package Installation

Agents may install R packages on the fly when the target library is container-owned or a named volume.

Example:

```yaml
environment:
  - R_LIBS_USER=/home/claude/R/library

volumes:
  - rock-r-library:/home/claude/R/library
```

Then the agent may run:

```r
install.packages("dplyr")
```

If the package needs to become part of a reproducible project, the agent should ask before changing mapped project files such as `renv.lock`, `DESCRIPTION`, or project setup scripts.

## Profiles

### Default: disposable clone / human push

```text
Canonical repo: outside Docker
Mapped workspace: empty or disposable
Agent: clone/pull, edit, test, produce patch
Agent commit/push: no
Human commit/push: yes
```

### System-free / mapped-readonly

```text
Container-owned paths: full agent access
Mapped folders: read-only
Agent writes proposals to: /work/proposed
Human approval needed for mapped-folder edits: yes
Human commit/push: yes, outside Docker
```

### Approved edit session

```text
Container-owned paths: full agent access
Selected mapped folder: read-write for the approved task
Human approval needed before starting: yes
Agent commit/push: no
Human review before commit/push: yes
```

### Synthetic autopilot

```text
Container-owned paths: full agent access
Selected synthetic mapped folder: read-write
Use only for disposable or backed-up synthetic workspaces
Agent commit/push: no
Human review before commit/push: yes
```

### Sensitive mode

```text
Container-owned paths: normal tools only
Mapped folders: read-only
No automatic edits to mapped files
No broad mounted credentials
No commit/push from Docker
```

## Agent Startup Boundary Instruction

Agents should receive this instruction at startup:

```text
You are running inside Rock.
You may freely use container-owned tools and folders.
Mapped folders are human-controlled boundaries.
You may read mapped folders, but you must ask before changing, deleting, moving, or generating files into them.
Use /work/scratch for experiments and /work/proposed for proposed changes.
Prefer working in a disposable clone under /workspace rather than editing the canonical repo.
Before applying changes to mapped folders, summarize the intended change and wait for approval.
Do not commit or push from inside Docker.
Produce patch files, diffs, summaries, and test logs for human review.
The human commits and pushes outside Docker.
```

## Current Decision

Rock should give agents high authority inside the container while protecting mapped host folders and Git publishing by default.

Preferred implementation:

```text
full container-owned access
+ disposable mapped agent workspace
+ writable scratch/proposed volumes
+ no push-capable credentials in Docker
+ no commit/push by agents
+ human review, commit, and push outside Docker
```
