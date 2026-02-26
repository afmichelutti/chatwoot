---
description: Check project status and next actions
---

# GSD Progress

Check project status and intelligently route to next action.

## Usage

```
/gsd-progress
```

## Process

### Step 1: Load State

Read:
- `.planning/STATE.md` - Current position
- `.planning/ROADMAP.md` - Phase breakdown
- `.planning/phases/*/` - All phase directories

### Step 2: Calculate Progress

For each phase:
1. Check if `PLAN.md` exists → Planned
2. Check if `SUMMARY.md` exists → Completed
3. Otherwise → Not started

Calculate:
- Total phases
- Completed phases
- Current phase (first incomplete)
- Completion percentage

### Step 3: Display Progress

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 GSD ► PROGRESS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

[████████░░░░░░░░░░░░] 40% Complete

## Phase Status

| #   | Phase         | Status        |
| --- | ------------- | ------------- |
| 1   | Foundation    | ✓ Complete    |
| 2   | Core Features | ✓ Complete    |
| 3   | API Layer     | → In Progress |
| 4   | Frontend      | ○ Not Started |
| 5   | Polish        | ○ Not Started |

## Current Position

**Phase 3: API Layer**
Goal: [goal from ROADMAP.md]
Requirements: REQ-API-01, REQ-API-02

## Recent Work

[Summary from last completed SUMMARY.md]

## Key Decisions

[From STATE.md decisions section]

## Open Issues

[From STATE.md issues section]
```

### Step 4: Suggest Next Action

Based on current state:

**If current phase has no plan:**
```
## Next Step
Phase 3 needs a plan.
→ /gsd-plan-phase 3
```

**If current phase has plan but not complete:**
```
## Next Step
Phase 3 is planned and ready.
→ /gsd-execute-phase 3
```

**If all phases complete:**
```
## Milestone Complete! 🎉
All phases finished.
→ /gsd-complete-milestone
```

### Step 5: Offer Actions

Present options:
- Execute suggested next step
- View specific phase details
- Check requirements coverage
- Review recent decisions

## Output

Displays:
- Visual progress bar
- Phase status table
- Current position details
- Suggested next action
