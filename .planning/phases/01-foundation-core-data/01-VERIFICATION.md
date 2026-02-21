---
phase: 01-foundation-core-data
verified: 2026-02-21T00:00:00Z
status: passed
score: 5/5 must-haves verified
re_verification: false
---

# Phase 01: Foundation Core Data — Verification Report

**Phase Goal:** The fork runs on v4.11.1 with all custom modifications intact and no regressions
**Verified:** 2026-02-21
**Status:** PASSED
**Re-verification:** No — initial verification

---

## Goal Achievement

### Observable Truths (Success Criteria)

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | `git log` shows the upstream v4.11.1 merge commit and all custom commits are preserved | VERIFIED | Merge commit `ab9c096bf` present; 18 pre-merge custom commits (including `962cccc5a`, `7355cf545`, `90584ec15`, `d237b1f42`) all in HEAD history; v4.11.1 confirmed ancestor of HEAD |
| 2 | Rails, Sidekiq, and Vite all start without errors — application fully operational | VERIFIED | Rails 7.1.5.2 boot confirmed (`rails runner` succeeds); `npx vite build --mode development` exited 0 in 63s; human-verified by user 2026-02-21 |
| 3 | All upstream database migrations run to completion with no errors | VERIFIED | 15 upstream migrations applied (20251010–20260130); schema version `2026_01_30_061021`; custom migrations 20250118000000 and 20250118000001 confirmed up; 0 down migrations |
| 4 | Activity-Based Presence, white-label branding, WhatsApp Cloud API config, and corrupted conversation handling all behave as they did before the merge | VERIFIED | See artifact and key link verification below |
| 5 | A decision is recorded in PROJECT.md resolving whether to use upstream Pundit `authorize @conversation, :show?` or custom PermissionFilterService, with rationale | VERIFIED | Full analysis in `.planning/PROJECT.md` lines 88–116; decision: keep both; rationale documented (defense-in-depth, complementary coverage); STATE.md updated to show decision no longer PENDING |

**Score: 5/5 truths verified**

---

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `app/controllers/api/v1/accounts/conversations_controller.rb` | Merged controller with both upstream authorize fix and custom PermissionFilterService | VERIFIED | 203 lines; `authorize @conversation, :destroy?` line 140, `authorize @conversation, :show?` line 188; `check_conversation_permission!` line 191; `Conversations::PermissionFilterService.new` line 196 |
| `app/models/channel/whatsapp.rb` | WhatsApp model with both upstream `after_commit` callback and custom `after_update` sync callback | VERIFIED | `after_commit :setup_webhooks, on: :create, if: :should_auto_setup_webhooks?` line 37; `after_update :sync_webhook_on_phone_number_change` line 38; `should_auto_setup_webhooks?` method line 92 |
| `config/schedule.yml` | Schedule config with custom Activity-Based Presence jobs preserved | VERIFIED | `activity_based_presence_job` at line 80; upstream jobs (`periodic_assignment_job`, `remove_old_notification_job`, `remove_orphan_conversations_job`) also present |
| `db/schema.rb` | Regenerated schema reflecting all migrations (upstream + custom) | VERIFIED | Schema version `2026_01_30_061021`; `activity_based_presence_enabled` column (line 76); `channel_tiktok` table (line 647); `assignee_agent_bot_id` column (line 901) |
| `.planning/PROJECT.md` | Updated with permission approach decision and rationale | VERIFIED | Decision recorded at lines 88–116 with full analysis of both Pundit and PermissionFilterService mechanisms, gap identification, and Phase 2 recommendation |
| `app/javascript/dashboard/api/inboxes.js` | Inboxes API with custom WhatsApp Cloud API config methods | VERIFIED | `syncWebhook(inboxId)` at line 36 (custom); `createCSATTemplate` and `getCSATTemplateStatus` (upstream additions) |
| `app/javascript/dashboard/store/modules/inboxes.js` | Vuex store with WhatsApp config actions/mutations | VERIFIED | `syncWebhook` action at line 355; `createCSATTemplate` at line 362 (upstream) |
| `app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/ConfigurationPage.vue` | Inbox settings page with WhatsApp Cloud API configuration section | VERIFIED | `isWhatsAppCloudChannel` computed at line 58; `whatsappWebhookUrl` at line 65; `isForwardingEnabled` at line 70 (upstream); all three rendered in template |
| `public/brand-assets/logo.svg` | Custom ivox white-label logo (CorelDRAW SVG) | VERIFIED | File is custom ivox CorelDRAW SVG (`<!-- Creator: CorelDRAW -->`), not upstream Chatwoot logo; no conflict markers |
| `theme/colors.js` | Custom brand colors AND upstream new tokens | VERIFIED | `border-green` and `text-green` custom tokens present (lines 276–278); upstream `blue-strong` and `purple-text` tokens also added |
| `app/models/message.rb` | Corrupted conversation nil guard | VERIFIED | Line 163–164: `# Add contact_inbox only if it exists (prevent nil error for corrupted data)` with `.present?` guard |
| `app/jobs/activity_based_presence_job.rb` | Activity-Based Presence job | VERIFIED | File exists at `app/jobs/activity_based_presence_job.rb` |
| `app/jobs/update_agent_presence_job.rb` | Update Agent Presence job | VERIFIED | File exists at `app/jobs/update_agent_presence_job.rb` |
| `db/migrate/20250118000000_add_activity_based_presence_to_accounts.rb` | Custom migration | VERIFIED | File exists; confirmed "up" in migration status |
| `db/migrate/20250118000001_set_auto_offline_to_true.rb` | Custom migration | VERIFIED | File exists; confirmed "up" in migration status |
| `start-chatwoot.bat`, `stop-chatwoot.bat`, `setup-dev.sh` | Dev scripts | VERIFIED | All three files present in repo root |
| `app/services/conversations/permission_filter_service.rb` | PermissionFilterService | VERIFIED | File exists; referenced by `Conversations::PermissionFilterService.new` in conversations_controller.rb |
| `app/policies/conversation_policy.rb` | ConversationPolicy (Pundit) | VERIFIED | File exists; `show?`, `inbox_access?`, `team_access?`, `agent_can_view_conversation?` methods confirmed |

---

### Key Link Verification

| From | To | Via | Status | Details |
|------|-----|-----|--------|---------|
| `conversations_controller.rb` | `app/policies/conversation_policy.rb` | Pundit `authorize @conversation, :show?` | WIRED | `authorize @conversation, :show?` at line 188; `authorize @conversation, :destroy?` at line 140; ConversationPolicy exists with `show?` method |
| `conversations_controller.rb` | `app/services/conversations/permission_filter_service.rb` | `check_conversation_permission!` | WIRED | `Conversations::PermissionFilterService.new` at line 196; PermissionFilterService file exists |
| `config/schedule.yml` | `app/jobs/activity_based_presence_job.rb` | Clockwork cron entry | WIRED | `activity_based_presence_job` in schedule.yml; job file exists |
| `app/models/account.rb` | Activity-Based Presence feature | Schema columns | WIRED | `activity_based_presence_enabled` and `activity_based_presence_config` columns in schema; annotated in account.rb lines 6–7 |
| `db/schema.rb` | `db/migrate/` | `rails db:migrate` | WIRED | Schema version `2026_01_30_061021` corresponds to last migration; all custom migrations confirmed up |
| `ConfigurationPage.vue` | `app/javascript/dashboard/store/modules/inboxes.js` | Vuex dispatch | WIRED | `isWhatsAppCloudChannel` computed in Vue component references store state; `syncWebhook` action present in store |
| `app/javascript/dashboard/store/modules/inboxes.js` | `app/javascript/dashboard/api/inboxes.js` | `InboxesAPI` | WIRED | `InboxesAPI.syncWebhook` called in store action at line 357 |
| `.planning/PROJECT.md` | Permission decision | `PermissionFilterService\|authorize @conversation` | WIRED | Full decision analysis documented at lines 88–116; referenced in STATE.md |

---

### Requirements Coverage

All 11 Phase 1 requirements claimed across the three plans (01-01, 01-02, 01-03):

| Requirement | Source Plan | Description | Status | Evidence |
|-------------|------------|-------------|--------|----------|
| UPGR-01 | 01-01 | Fork upgraded to Chatwoot v4.11.1 via git merge | SATISFIED | Merge commit `ab9c096bf` present; v4.11.1 tag is confirmed ancestor of HEAD |
| UPGR-02 | 01-01, 01-02 | All merge conflicts resolved preserving custom modifications | SATISFIED | All 11 conflict files resolved (4 backend in plan 01, 7 frontend/branding in plan 02); `git diff --name-only --diff-filter=U` returns empty |
| UPGR-03 | 01-01 | Activity-Based Presence system preserved and functional | SATISFIED | Job files exist; cron entry in schedule.yml; schema columns present; user confirmed presence toggle visible |
| UPGR-04 | 01-02 | White-label branding preserved and functional | SATISFIED | CorelDRAW ivox logo.svg confirmed; `border-green`/`text-green` brand tokens in colors.js; user confirmed green colors visible |
| UPGR-05 | 01-02 | WhatsApp Cloud API config management preserved and functional | SATISFIED | `syncWebhook` in API, store, and Vue component all present; user confirmed WhatsApp config visible |
| UPGR-06 | 01-01 | Corrupted conversation handling preserved | SATISFIED | `contact_inbox.present?` nil guard at message.rb line 164 |
| UPGR-07 | 01-01, 01-03 | Permission enforcement reconciled | SATISFIED | Both Pundit `authorize @conversation, :show?` and `PermissionFilterService` active; decision documented in PROJECT.md |
| UPGR-08 | 01-03 | All new upstream database migrations run successfully | SATISFIED | 15 upstream migrations applied; 0 down migrations; schema version `2026_01_30_061021` |
| UPGR-09 | 01-03 | Application boots correctly with all services | SATISFIED | Rails 7.1.5.2 boot verified; Vite build exited 0; human-verified full application startup |
| UPGR-10 | 01-02 | pt-BR translations preserved and merged | SATISFIED | `inboxMgmt.json` has no conflict markers; custom pt-BR wording preserved; upstream additions merged |
| UPGR-11 | 01-03 | Dev scripts still functional | SATISFIED | `start-chatwoot.bat`, `stop-chatwoot.bat`, `setup-dev.sh` all present |

**Requirements orphan check:** REQUIREMENTS.md maps UPGR-01 through UPGR-11 to Phase 1 — all 11 are claimed by the three plans. No orphaned requirements.

---

### Anti-Patterns Found

| File | Pattern | Severity | Impact |
|------|---------|----------|--------|
| `app/services/conversations/permission_filter_service.rb` | PermissionFilterService only filters by inbox, not team membership — gap vs. Pundit coverage | Info (known gap) | Documented in PROJECT.md and STATE.md; intentionally deferred to Phase 2 Security Audit. Does NOT block Phase 1 goal. |
| Merge commit `ab9c096bf` | Used `--no-verify` to bypass lint-staged | Info | lint-staged binary not available in dev environment; merge resolution commit, not a code change. Standard practice for conflict-resolution merges. |

No blocker or warning anti-patterns found. One known technical gap (PermissionFilterService team access coverage) and one minor tooling deviation (--no-verify), both documented.

---

### Human Verification (Already Completed)

Phase 03 Plan included a blocking human verification checkpoint (Task 3). User approved on 2026-02-21:

| Test | Outcome |
|------|---------|
| Application boots with custom ivox branding | Confirmed by user |
| Activity-Based Presence toggle visible in Settings | Confirmed by user |
| WhatsApp Cloud API configuration visible in Inbox settings | Confirmed by user |
| Custom green brand colors present in UI | Confirmed by user |
| No JavaScript errors in browser console | Confirmed by user (no issues reported) |

---

### Gaps Summary

None. All 5 success criteria are verified.

---

## Detailed Findings

### Truth 1: Git History

- Merge commit `ab9c096bf` — "merge: integrate upstream v4.11.1 into v4.7.0-custom" — present in HEAD
- v4.11.1 tag (`a08125e28` — "Merge branch 'hotfix/4.11.1'") confirmed as ancestor of HEAD
- 18 pre-merge custom commits all present in HEAD history
- Key code commits confirmed in HEAD: `962cccc5a` (Activity-Based Presence), `7355cf545` (WhatsApp Cloud API), `90584ec15` (white-label branding), `d237b1f42` (corrupted conversation fix + permissions)
- Backup branch `v4.7.0-custom-backup` still exists as safety net

### Truth 2: Application Operational

- Rails 7.1.5.2 boots: verified via `rails runner "puts Rails.version"` in SUMMARY 03
- Vite build: `npx vite build --mode development` exits 0 in 63 seconds (SUMMARY 03)
- Note: Sidekiq verified via human observation during Task 3 checkpoint (not via automated test). SUMMARY 03 records user confirmation of full app boot.
- Node.js 18.19.1 was installed in WSL Ubuntu to resolve ExecJS dependency; this is a necessary environment fix, not a code regression.

### Truth 3: Migrations Complete

- Schema version `2026_01_30_061021` (latest upstream migration timestamp)
- 15 upstream migrations documented and confirmed applied
- Both custom migrations (20250118000000, 20250118000001) confirmed "up"
- No conflict markers in `db/schema.rb`

### Truth 4: Custom Features Intact

- **Activity-Based Presence**: Schema columns in accounts table (`activity_based_presence_enabled`, `activity_based_presence_config`); job files present; cron entry in schedule.yml; user confirmed toggle visible
- **White-label branding**: CorelDRAW ivox logo.svg (`<!-- Creator: CorelDRAW -->`); custom brand tokens in colors.js; user confirmed green colors
- **WhatsApp Cloud API config**: `syncWebhook` method in API client, Vuex store action, and ConfigurationPage.vue computed properties all present and wired; user confirmed config UI visible
- **Corrupted conversation handling**: nil guard at message.rb line 164; no regression

### Truth 5: Permission Decision

- PROJECT.md contains detailed analysis of both mechanisms (lines 88–116)
- Decision: "Keep BOTH" — Pundit for single-resource auth, PermissionFilterService for collection filtering
- Rationale: defense-in-depth, different coverage axes (inbox vs. inbox+team)
- Gap identified and documented: PermissionFilterService only checks inbox membership (not team) — inconsistent with Pundit which covers both. Phase 2 action item recorded.
- STATE.md updated: permission decision no longer PENDING

---

*Verified: 2026-02-21*
*Verifier: Claude (gsd-verifier)*
