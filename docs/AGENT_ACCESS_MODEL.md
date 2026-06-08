# Rock Agent Access Model

## Purpose

Rock uses a two-zone permission model.

```text
Container zone:
  Agents can use the container as a full development workstation.

Mapped-folder zone:
  Agents can read by default, but must ask before changing host-mapped files.
```

This gives agents freedom inside the disposable environment while keeping host/project files under human control.

## Core Rule

```text
Agents may freely operate inside container-owned paths.
Agents may read mapped host folders.
Agents must ask before modifying mapped host folders.
```

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

## Technical Enforcement

Instruction alone is not enough. If Docker mounts a folder as read-write, the agent can technically change it.

Therefore the safest default implementation is:

```text
/workspace       mapped read-only project folder
/work/proposed   writable proposed-change area
/work/scratch    writable experiment area
```

The agent should read from `/workspace`, write proposed edits to `/work/proposed`, and ask before applying them back to `/workspace`.

## Recommended Compose Pattern

```yaml
services:
  rock:
    volumes:
      - ./workspace/synthetic-only:/workspace:ro
      - rock-proposed:/work/proposed
      - rock-scratch:/work/scratch
      - rock-r-library:/home/claude/R/library
      - ./config/skills:/opt/rock/skills:ro

volumes:
  rock-proposed:
  rock-scratch:
  rock-r-library:
```

## Change Workflow

When the agent wants to change mapped files:

```text
1. Inspect files in /workspace.
2. Create edited copies or patch files in /work/proposed.
3. Summarize the intended changes.
4. Ask for permission.
5. Apply changes only after approval.
```

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

### Default: system-free / mapped-readonly

```text
Container-owned paths: full agent access
Mapped folders: read-only
Agent writes proposals to: /work/proposed
Human approval needed for mapped-folder edits: yes
```

### Approved edit session

```text
Container-owned paths: full agent access
Selected mapped folder: read-write for the approved task
Human approval needed before starting: yes
Review needed before commit/push: yes
```

### Synthetic autopilot

```text
Container-owned paths: full agent access
Selected synthetic mapped folder: read-write
Use only for disposable or backed-up synthetic workspaces
Review needed before commit/push: yes
```

### Sensitive mode

```text
Container-owned paths: normal tools only
Mapped folders: read-only
No automatic edits to mapped files
No broad mounted credentials
```

## Agent Startup Boundary Instruction

Agents should receive this instruction at startup:

```text
You are running inside Rock.
You may freely use container-owned tools and folders.
Mapped folders are human-controlled boundaries.
You may read mapped folders, but you must ask before changing, deleting, moving, or generating files into them.
Use /work/scratch for experiments and /work/proposed for proposed changes.
Before applying changes to mapped folders, summarize the intended change and wait for approval.
Do not push to GitHub without explicit approval.
```

## Current Decision

Rock should give agents high authority inside the container while protecting mapped host folders by default.

Preferred implementation:

```text
full container-owned access
+ read-only mapped folders
+ writable scratch/proposed volumes
+ explicit approval before mapped-folder changes
```
