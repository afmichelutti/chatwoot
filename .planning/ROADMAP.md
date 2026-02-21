# Roadmap: Chatwoot Fork — v4.11.1 Upgrade & Security Audit

## Overview

Upgrade the ivox Chatwoot fork from v4.7.0-custom to v4.11.1 without losing custom modifications, then audit and harden agent conversation isolation across every access vector, then verify the combined result with a full RSpec test suite. Three sequential phases — each must complete before the next begins.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (1.1, 2.1): Urgent insertions (marked with INSERTED)

Decimal phases appear between their surrounding integers in numeric order.

- [ ] **Phase 1: Merge** - Integrate upstream v4.11.1 and resolve all conflicts while preserving custom modifications
- [ ] **Phase 2: Security Audit** - Audit and harden agent conversation isolation across all API access vectors
- [ ] **Phase 3: Testing** - Write and run RSpec tests that verify permission boundaries for all roles

## Phase Details

### Phase 1: Merge
**Goal**: The fork runs on v4.11.1 with all custom modifications intact and no regressions
**Depends on**: Nothing (first phase)
**Requirements**: UPGR-01, UPGR-02, UPGR-03, UPGR-04, UPGR-05, UPGR-06, UPGR-07, UPGR-08, UPGR-09, UPGR-10, UPGR-11
**Success Criteria** (what must be TRUE):
  1. `git log` shows the upstream v4.11.1 merge commit and all 13 custom commits are preserved in branch history
  2. Rails, Sidekiq, and Vite all start without errors — the application is fully operational
  3. All upstream database migrations run to completion with no errors
  4. Activity-Based Presence, white-label branding, WhatsApp Cloud API config, and corrupted conversation handling all behave as they did before the merge
  5. A decision is recorded in PROJECT.md resolving whether to use the upstream Pundit `authorize @conversation, :show?` or the custom `PermissionFilterService`, with rationale
**Plans**: 3 plans

Plans:
- [ ] 01-01-PLAN.md -- Execute git merge v4.11.1 and resolve backend/config conflicts
- [ ] 01-02-PLAN.md -- Resolve frontend/branding conflicts and finalize merge commit
- [ ] 01-03-PLAN.md -- Run migrations, verify boot, and record permission approach decision

### Phase 2: Security Audit
**Goal**: No agent can access any conversation they are not authorized to see, through any endpoint or interface
**Depends on**: Phase 1
**Requirements**: SECR-01, SECR-02, SECR-03, SECR-04, SECR-05, SECR-06, SECR-07, SECR-08, SECR-09, SECR-10
**Success Criteria** (what must be TRUE):
  1. An agent logged in as Agent A cannot retrieve Agent B's conversation data via direct URL, contact history tab, search endpoint, filter endpoint, or contact profile API — every vector returns 403 or an empty result
  2. An agent cannot reassign a conversation they do not own to themselves — the assignment endpoint rejects the request with a permission error
  3. WebSocket channel subscriptions do not deliver conversation payloads to agents who lack permission for those conversations
  4. All conversation-related API endpoints enforce permission checks at the controller level, using Pundit policies with one consistent approach (no mixed strategies)
**Plans**: TBD

Plans:
- [ ] 02-01: [To be planned]

### Phase 3: Testing
**Goal**: RSpec tests exist and pass, proving the permission model is correct for agents, supervisors, and admins across every access vector hardened in Phase 2
**Depends on**: Phase 2
**Requirements**: TEST-01, TEST-02, TEST-03, TEST-04, TEST-05, TEST-06, TEST-07, TEST-08
**Success Criteria** (what must be TRUE):
  1. `bundle exec rspec` runs the full permission/isolation spec suite with zero failures
  2. A spec explicitly asserts that an agent can access their own assigned conversation (allowed path verified)
  3. Specs explicitly assert that an agent is denied access to another agent's conversation via direct endpoint, contact history, search, filter, and reassignment — one spec per vector
  4. Specs assert that supervisors can see all conversations in their team and that admins can see all conversations in the system
**Plans**: TBD

Plans:
- [ ] 03-01: [To be planned]

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Merge | 2/3 | In Progress|  |
| 2. Security Audit | 0/TBD | Not started | - |
| 3. Testing | 0/TBD | Not started | - |
