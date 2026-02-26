---
description: Create detailed execution plan for a specific phase
---

# GSD Plan Phase

Create a detailed execution plan for a specific phase.

## Usage

```
/gsd-plan-phase <phase-number>
```

Example: `/gsd-plan-phase 1`

## Process

### Step 1: Load Context

Read these files:
- `.planning/ROADMAP.md` - Get phase details
- `.planning/REQUIREMENTS.md` - Get requirements for this phase
- `.planning/STATE.md` - Get current context
- `.planning/config.json` - Get workflow settings

### Step 2: Research (Optional)

If `config.workflow.research` is true:
1. Research how to implement this phase's requirements
2. Look for patterns, gotchas, best practices
3. Surface any concerns before planning

### Step 3: Create Plan

Use template from:
`C:\Users\afmic\.gemini\get-shit-done\templates\phase-prompt.toml`

Create `.planning/phases/XX-phase-name/XX-YY-PLAN.md`:

```markdown
# Phase X Plan Y: [Title]

## Goal
[What this plan achieves]

## Requirements Covered
- REQ-ID: [requirement text]

## Tasks

### 1. [Task Title]
**What:** [Specific deliverable]
**How:** [Implementation approach]
**Files:** [Files to create/modify]
**Verification:** [How to verify it works]

### 2. [Task Title]
...

## Success Criteria
- [ ] [Observable outcome 1]
- [ ] [Observable outcome 2]

## Dependencies
- [Any prerequisites]

## Risks
- [Potential issues and mitigations]
```

### Step 4: Plan Check (Optional)

If `config.workflow.plan_check` is true:
1. Verify plan actually achieves the phase goal
2. Check all requirements are addressed
3. Identify any gaps

### Step 5: Commit

```bash
git add .planning/phases/
git commit -m "docs: plan phase [N] - [phase name]"
```

### Step 6: Present Plan

Show the plan to user and offer:
- "Approve" - Ready to execute
- "Adjust" - Make changes
- "Add context" - More discussion needed

## Output

Creates:
- `.planning/phases/XX-phase-name/XX-YY-PLAN.md`

## Next Step

After planning: `/gsd-execute-phase <N>`
