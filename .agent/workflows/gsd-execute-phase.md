---
description: Execute all plans in a phase
---

# GSD Execute Phase

Execute all plans in a specific phase.

## Usage

```
/gsd-execute-phase <phase-number>
```

Example: `/gsd-execute-phase 1`

## Process

### Step 1: Load Plans

1. Read `.planning/phases/XX-phase-name/` directory
2. Find all `XX-YY-PLAN.md` files
3. Read `.planning/config.json` for execution settings

### Step 2: Execute Plans

For each plan in the phase:

1. **Read the plan** - Understand tasks and success criteria
2. **Execute tasks** - Implement each task in order
3. **Verify task** - Check verification criteria after each task
4. **Track progress** - Update as you go

If `config.parallelization` is true:
- Independent plans can run in parallel
- Dependent plans run sequentially

### Step 3: Create Summary

After completing each plan, create `XX-YY-SUMMARY.md`:

```markdown
# Phase X Plan Y: Summary

## Completed
- [x] [Task 1 summary]
- [x] [Task 2 summary]

## Files Changed
- `path/to/file.ts` - [what changed]
- `path/to/new-file.ts` - [NEW] [what it does]

## Verification
- [x] [Success criteria 1] - Passed
- [x] [Success criteria 2] - Passed

## Notes
[Any important observations or decisions made during execution]
```

### Step 4: Phase Verification (Optional)

If `config.workflow.verifier` is true:
1. Verify all phase success criteria are met
2. Check requirements are satisfied
3. Create verification report

### Step 5: Update State

Update `.planning/STATE.md`:
- Mark phase as completed
- Update current position
- Note any issues or decisions

Update `.planning/ROADMAP.md`:
- Mark phase requirements as done
- Update progress indicators

### Step 6: Commit

```bash
git add .
git commit -m "feat: complete phase [N] - [phase name]"
```

### Step 7: Present Results

Show:
- What was built
- Verification results
- Next step: `/gsd-plan-phase <N+1>` or `/gsd-progress`

## Output

Creates:
- `.planning/phases/XX-phase-name/XX-YY-SUMMARY.md` for each plan
- Actual code implementation

Updates:
- `.planning/STATE.md`
- `.planning/ROADMAP.md`

## Error Handling

If a task fails:
1. Document the issue in summary
2. Attempt to debug using `/gsd-debug`
3. If blocked, create issue note and move on
4. Report blockers at end of phase
