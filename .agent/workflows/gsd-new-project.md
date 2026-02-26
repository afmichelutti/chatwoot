---
description: Initialize a new project with deep context gathering
---

# GSD New Project

Initialize a new project through unified flow: questioning → research → requirements → roadmap.

## What This Creates

```
.planning/
├── PROJECT.md            # Project context
├── config.json           # Workflow preferences
├── research/             # Domain research (optional)
├── REQUIREMENTS.md       # Scoped requirements
├── ROADMAP.md            # Phase structure
└── STATE.md              # Project memory
```

## Process

### Phase 1: Setup

1. **Check if project already exists:**
   - If `.planning/PROJECT.md` exists, use `/gsd-progress` instead

2. **Initialize git repo** (if not present):
   ```bash
   git init
   ```

3. **Detect existing code (brownfield):**
   - Check for code files (*.ts, *.js, *.py, etc.)
   - If found, offer to run `/gsd-map-codebase` first

### Phase 2: Deep Questioning

Read the questioning guidelines from:
`C:\Users\afmic\.gemini\get-shit-done\references\questioning.md`

**Open the conversation:**
Ask: "What do you want to build?"

**Follow the thread:**
- Ask follow-up questions based on their response
- Challenge vagueness, make abstract concrete
- Surface assumptions, find edges, reveal motivation
- Keep exploring until you could write a clear PROJECT.md

**Decision gate:**
When ready, ask: "Ready to create PROJECT.md?"

### Phase 3: Write PROJECT.md

Use the template from:
`C:\Users\afmic\.gemini\get-shit-done\templates\project.toml`

Create `.planning/PROJECT.md` with:
- What This Is (2-3 sentences)
- Core Value (the ONE thing that must work)
- Requirements (Active, Out of Scope)
- Context
- Constraints
- Key Decisions

**Commit:**
```bash
git add .planning/PROJECT.md
git commit -m "docs: initialize project"
```

### Phase 4: Workflow Preferences

Ask user about:

1. **Mode:** YOLO (auto-approve) or Interactive (confirm each step)
2. **Depth:** Quick (3-5 phases) / Standard (5-8 phases) / Comprehensive (8-12 phases)
3. **Execution:** Parallel or Sequential
4. **Git:** Commit planning docs or keep local-only
5. **Agents:** Research, Plan Check, Verifier (on/off)

Create `.planning/config.json`:
```json
{
  "mode": "yolo|interactive",
  "depth": "quick|standard|comprehensive",
  "parallelization": true,
  "commit_docs": true,
  "workflow": {
    "research": true,
    "plan_check": true,
    "verifier": true
  }
}
```

**Commit:**
```bash
git add .planning/config.json
git commit -m "chore: add project config"
```

### Phase 5: Research (Optional)

Ask: "Research the domain ecosystem before defining requirements?"

If yes, create `.planning/research/` with:
- STACK.md - Standard stack for this domain
- FEATURES.md - Table stakes vs differentiators
- ARCHITECTURE.md - Typical structure
- PITFALLS.md - Common mistakes
- SUMMARY.md - Synthesized findings

### Phase 6: Define Requirements

Read from research or gather through conversation:
- v1 Requirements (what to build now)
- v2 Requirements (deferred)
- Out of Scope (explicit exclusions)

Use template from:
`C:\Users\afmic\.gemini\get-shit-done\templates\requirements.toml`

Create `.planning/REQUIREMENTS.md` with REQ-IDs (AUTH-01, CONT-02, etc.)

**Commit:**
```bash
git add .planning/REQUIREMENTS.md
git commit -m "docs: define v1 requirements"
```

### Phase 7: Create Roadmap

Use template from:
`C:\Users\afmic\.gemini\get-shit-done\templates\roadmap.toml`

Create `.planning/ROADMAP.md`:
- Derive phases from requirements
- Map every v1 requirement to exactly one phase
- Define 2-5 success criteria per phase

Create `.planning/STATE.md`:
- Project reference
- Current position
- Session continuity

**Present roadmap for approval:**
Show the proposed phase structure and ask for confirmation.

**Commit:**
```bash
git add .planning/ROADMAP.md .planning/STATE.md .planning/REQUIREMENTS.md
git commit -m "docs: create roadmap"
```

### Phase 8: Done

Display completion message with:
- All created artifacts
- Phase count and requirement count
- Next step: `/gsd-plan-phase 1`

## Success Criteria

- [ ] .planning/ directory created
- [ ] Git repo initialized
- [ ] Deep questioning completed
- [ ] PROJECT.md captures full context
- [ ] config.json has workflow preferences
- [ ] Research completed (if selected)
- [ ] REQUIREMENTS.md created with REQ-IDs
- [ ] ROADMAP.md with phases and success criteria
- [ ] STATE.md initialized
- [ ] User knows next step is `/gsd-plan-phase 1`
