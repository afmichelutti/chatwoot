---
description: Show GSD command reference and available workflows
---

# GSD Command Reference

**GSD** (Get Shit Done) creates hierarchical project plans optimized for solo agentic development.

## Quick Start

1. `/gsd-new-project` - Initialize project (includes research, requirements, roadmap)
2. `/gsd-plan-phase 1` - Create detailed plan for first phase
3. `/gsd-execute-phase 1` - Execute the phase

## Core Workflow

```
/gsd-new-project → /gsd-plan-phase → /gsd-execute-phase → repeat
```

## Available Commands

### Project Initialization

| Command             | Description                                   |
| ------------------- | --------------------------------------------- |
| `/gsd-new-project`  | Initialize new project through unified flow   |
| `/gsd-map-codebase` | Map existing codebase for brownfield projects |

### Phase Planning

| Command                   | Description                       |
| ------------------------- | --------------------------------- |
| `/gsd-discuss-phase <n>`  | Articulate vision before planning |
| `/gsd-research-phase <n>` | Deep research for niche domains   |
| `/gsd-plan-phase <n>`     | Create detailed execution plan    |

### Execution

| Command                  | Description                       |
| ------------------------ | --------------------------------- |
| `/gsd-execute-phase <n>` | Execute all plans in a phase      |
| `/gsd-quick`             | Quick mode for small ad-hoc tasks |

### Progress & Session

| Command            | Description                   |
| ------------------ | ----------------------------- |
| `/gsd-progress`    | Check status and next actions |
| `/gsd-resume-work` | Resume from previous session  |
| `/gsd-pause-work`  | Create context handoff        |

### Debugging

| Command              | Description                                |
| -------------------- | ------------------------------------------ |
| `/gsd-debug [issue]` | Systematic debugging with persistent state |

## Files & Structure

```
.planning/
├── PROJECT.md            # Project vision
├── ROADMAP.md            # Current phase breakdown
├── STATE.md              # Project memory & context
├── config.json           # Workflow mode & gates
├── codebase/             # Codebase map (brownfield)
└── phases/
    ├── 01-foundation/
    │   ├── 01-01-PLAN.md
    │   └── 01-01-SUMMARY.md
    └── 02-core-features/
        └── ...
```

## Workflow Modes

Set during `/gsd-new-project`:

- **YOLO Mode** - Auto-approves, just executes
- **Interactive Mode** - Confirms at each step

## Common Workflows

**Starting a new project:**
```
/gsd-new-project
/gsd-plan-phase 1
/gsd-execute-phase 1
```

**Resuming work:**
```
/gsd-progress
```

**Quick task:**
```
/gsd-quick
```

## References

GSD templates and references are stored in:
- `~/.gemini/get-shit-done/templates/`
- `~/.gemini/get-shit-done/references/`
