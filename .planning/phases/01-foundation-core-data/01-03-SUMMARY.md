---
phase: 01-foundation-core-data
plan: 03
subsystem: backend
tags: [migrations, rails-boot, vite-build, permissions, pundit, wsl, node]
dependency_graph:
  requires:
    - phase: 01-foundation-core-data
      plan: 01
      provides: [merge-complete]
    - phase: 01-foundation-core-data
      plan: 02
      provides: [merge-complete, frontend-whatsapp-config-preserved]
  provides:
    - migrations-complete
    - rails-boots
    - vite-builds
    - permission-decision-documented
  affects: [Phase 2 (Security Audit) — permission approach established]
tech-stack:
  added: [nodejs-18.19.1-wsl]
  patterns: [pundit-policy-check, permission-filter-service, defense-in-depth]
key-files:
  created: []
  modified:
    - db/schema.rb
    - .planning/PROJECT.md
    - .planning/STATE.md
key-decisions:
  - "Both Pundit authorize @conversation, show? AND PermissionFilterService kept — complementary coverage"
  - "ConversationPolicy covers inbox OR team access; PermissionFilterService covers inbox-only — gap to fix in Phase 2"
  - "Node.js 18.19.1 installed in WSL Ubuntu to satisfy ExecJS runtime requirement"
  - "Vite build runs from Windows side (npx vite build); Rails commands run in WSL — split environment"
requirements:
  - UPGR-07
  - UPGR-08
  - UPGR-09
  - UPGR-11
metrics:
  duration_minutes: 45
  tasks_completed: 3
  files_modified: 3
  completed_date: "2026-02-21"
---

# Phase 01 Plan 03: Migrations, Boot Verification, and Permission Decision Summary

**All 15 upstream database migrations applied, Rails 7.1.5.2 boots cleanly, Vite frontend build succeeds; permission approach decision documented: use both Pundit + PermissionFilterService with a team-access gap identified for Phase 2.**

## Performance

- **Duration:** ~45 min
- **Started:** 2026-02-21
- **Completed:** 2026-02-21
- **Tasks completed:** 3 of 3 (Task 3 human-verify approved by user 2026-02-21)
- **Files modified:** 3

## Accomplishments

### Task 1: Database Migrations and Boot Verification

- Applied all 15 upstream migrations (20251010 to 20260130):
  - AddNameToWebhooks
  - AddUniqueIndexToCompaniesDomain
  - AddIndexToConversationsIdentifier
  - AddAssigneeAgentBotIdToConversations
  - AddTiktokChannel
  - AddContactsCountToCompanies
  - ChangeSourceIdToText
  - ChangeMessagesSourceIdToText
  - ChangeWebhookUrlToText
  - RemoveCountryCodeFromConversationFilters
  - AddInternalObservationsToCsatSurveyResponses
  - AddObservationsAuditToCsatSurveyResponses
  - EnableCaptainTasksForExistingAccounts
  - AddIndexToReportingEventsForResponseDistribution
- Custom migrations 20250118000000 and 20250118000001 confirmed up
- Schema version: `2026_01_30_061021` (0 down migrations)
- Rails 7.1.5.2 boots successfully: `puts Rails.version` works
- Vite frontend build: `npx vite build --mode development` exits 0 in 1m 3s
- Dev scripts: start-chatwoot.bat, stop-chatwoot.bat, check-chatwoot.bat, setup-dev.sh all present

### Task 2: Permission Approach Decision

Analyzed merged conversations_controller.rb, ConversationPolicy, and PermissionFilterService.

**Decision: Keep BOTH approaches:**

| Mechanism | Scope | Checks |
|-----------|-------|--------|
| Pundit `authorize @conversation, :show?` | Single resource (show, update, destroy, etc.) | `inbox_access? OR team_access?` |
| `PermissionFilterService` | Collections (index, search, filter, contact history) | Inbox membership only |

**Key gap identified for Phase 2:** PermissionFilterService only filters by inbox — it does NOT cover team-only members. This creates inconsistency with Pundit which allows team-based access. Phase 2 must extend PermissionFilterService to include team membership.

**Where PermissionFilterService is applied:**
- `conversations_controller.rb#check_conversation_permission!` (individual access double-check)
- `contacts/conversations_controller.rb` (contact history conversations)
- `conversation_finder.rb` (index/search collection)
- `filter_service.rb` (filter endpoint)

## Task Commits

| Task | Commit | Files | Notes |
|------|--------|-------|-------|
| Task 1: Migrations and boot | `42eb83189` | `db/schema.rb` | 15 upstream migrations applied, all 0 down |
| Task 2: Permission decision | `3971362b4` | `.planning/PROJECT.md`, `.planning/STATE.md` | Both approaches documented with gap analysis |
| Task 3: Human verify | N/A | — | Approved by user: branding, presence toggle, WhatsApp config, green colors all confirmed |

## Files Created/Modified

- `db/schema.rb` — Updated to schema version 2026_01_30_061021 with all new tables (channel_tiktok, companies, etc.) and columns (assignee_agent_bot_id, contacts_count, etc.)
- `.planning/PROJECT.md` — Permission approach decision added with full analysis of both mechanisms and gap identification
- `.planning/STATE.md` — Permission decision resolved; Phase 2 items for PermissionFilterService gap added

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Node.js not installed in WSL Ubuntu**
- **Found during:** Task 1 (Rails db:migrate)
- **Issue:** `rails db:migrate` failed with `ExecJS::RuntimeUnavailable: Could not find a JavaScript runtime`. The `uglifier` gem in Gemfile requires ExecJS, which requires a JavaScript runtime. Node.js was only on Windows, not in WSL Ubuntu.
- **Fix:** Installed `nodejs` via `apt-get install nodejs npm` in WSL Ubuntu (as root). Node.js v18.19.1 installed.
- **Impact:** Rails commands now work in WSL
- **Committed in:** 42eb83189

**2. [Clarification] `pnpm build` script not configured; used `npx vite build`**
- **Plan said:** `pnpm build` for Vite compilation
- **Reality:** `package.json` has no `build` script; only `build:sdk` (library mode). The plan's fallback (`npx vite build --mode development`) was used instead.
- **Result:** Build succeeded (exit 0, 63 seconds)

**3. [Clarification] Schema dump TypeError after migrations**
- **Issue:** After migrations ran, the `db:schema:dump` step (triggered by the annotaterb post-task hook) had a `TypeError: no implicit conversion of Hash into String` error. This is a known Ruby 3.4.x / annotaterb compatibility issue.
- **Impact:** The schema.rb was still generated correctly by the migration process itself before the annotaterb hook ran. All migration data is in schema.rb correctly.
- **No fix needed:** The TypeError is in the annotate step (cosmetic schema comments), not in the migration itself.

### Out of Scope

The annotaterb TypeError (model annotation failure) is a pre-existing Ruby 3.4.x compatibility issue unrelated to our changes. Deferred to a future maintenance task.

## Permission Analysis (Plan 03 Key Outcome)

```ruby
# ConversationPolicy#show? — covers individual access
def show?
  administrator? || agent_bot? || agent_can_view_conversation?
end

def agent_can_view_conversation?
  inbox_access? || team_access?  # BOTH inbox AND team
end

# PermissionFilterService#accessible_conversations — covers collection filtering
def accessible_conversations
  conversations.where(inbox: user.inboxes.where(account_id: account.id))
  # ONLY inbox — team not covered
end
```

**Phase 2 fix needed:**
```ruby
def accessible_conversations
  # Fix: include team-based access to match Pundit coverage
  inbox_conversations = conversations.where(inbox: user.inboxes.where(account_id: account.id))
  team_conversations = conversations.where(team: user.teams.where(account_id: account.id))
  inbox_conversations.or(team_conversations)
end
```

## User Setup Required

None — no external service configuration required. Application verified running by user.

## Next Phase Readiness

Phase 1 (Merge) is fully complete — all 3 plans executed and verified:
- Migrations: complete and verified (all 15 upstream + 2 custom = 0 down)
- Rails boot: confirmed working (Rails 7.1.5.2)
- Vite build: confirmed working (exit 0, 63 seconds)
- Permission approach: documented, ready for Phase 2 Security Audit
- Human verification: approved — custom branding, Activity-Based Presence toggle, WhatsApp Cloud API config, green brand colors all confirmed working

**Phase 2 Security Audit prerequisites ready:**
- Permission approach: Pundit + PermissionFilterService (complementary)
- Gap identified: PermissionFilterService must be extended to include team membership (not just inbox membership)
- Contact tab conversation history vulnerability documented for Phase 2 audit

## Self-Check

### Files verified:
- [x] `db/schema.rb` — schema version 2026_01_30_061021, contains channel_tiktok, assignee_agent_bot_id, activity_based_presence columns
- [x] `.planning/PROJECT.md` — contains PermissionFilterService and Pundit decision
- [x] `.planning/STATE.md` — permission decision no longer PENDING

### Commits verified:
- [x] 42eb83189 — feat(01-03): run all database migrations and verify application boot
- [x] 3971362b4 — docs(01-03): record permission approach decision

### Migration verification:
- [x] All migrations "up" (0 down)
- [x] Custom migrations 20250118000000 and 20250118000001 confirmed up
- [x] Schema version 2026_01_30_061021

### Human verification (Task 3):
- [x] Application boots with custom ivox branding — confirmed by user
- [x] Activity-Based Presence toggle visible in Settings — confirmed by user
- [x] WhatsApp Cloud API configuration visible — confirmed by user
- [x] Custom green brand colors present — confirmed by user
- [x] No issues reported by user

## Self-Check: PASSED
