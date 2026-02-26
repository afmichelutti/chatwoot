---
description: Quick mode for small ad-hoc tasks
---

# GSD Quick

Execute small, ad-hoc tasks with GSD guarantees but skip optional agents.

## Usage

```
/gsd-quick
```

Or with description:
```
/gsd-quick Fix the login button styling
```

## When to Use

- Small, well-defined tasks
- You know exactly what needs to be done
- Task is too small to need full planning
- Quick bug fixes or minor features

## When NOT to Use

- Complex features spanning multiple files
- Uncertain about approach
- Tasks that might have dependencies
- Anything that affects core architecture

## Process

### Step 1: Understand Task

If no description provided, ask:
"What do you need done?"

Clarify:
- What exactly should change?
- What files are involved?
- How will we verify it works?

### Step 2: Quick Plan

Create `.planning/quick/NNN-slug/PLAN.md`:

```markdown
# Quick Task: [Title]

## Goal
[One-liner description]

## Tasks
1. [task 1]
2. [task 2]

## Verification
- [ ] [How to verify]

## Files
- [files to change]
```

### Step 3: Execute

1. Implement the changes
2. Verify each step works
3. Test the final result

### Step 4: Summary

Create `.planning/quick/NNN-slug/SUMMARY.md`:

```markdown
# Quick Task: [Title] - Complete

## Done
- [x] [what was done]

## Files Changed
- `file.ts` - [change]

## Verified
- [x] [verification passed]
```

### Step 5: Update State

Update `.planning/STATE.md`:
- Add to quick tasks completed
- Note any relevant decisions

### Step 6: Commit

```bash
git add .
git commit -m "fix: [quick task description]"
```

## Output

Creates:
- `.planning/quick/NNN-slug/PLAN.md`
- `.planning/quick/NNN-slug/SUMMARY.md`
- Actual code changes

## Comparison

| Aspect       | Quick Mode    | Full Mode  |
| ------------ | ------------- | ---------- |
| Research     | Skipped       | Optional   |
| Plan Check   | Skipped       | Optional   |
| Verification | Basic         | Full       |
| Tracking     | STATE.md only | ROADMAP.md |
| Commits      | Single        | Per phase  |
