---
phase: 01-foundation-core-data
plan: 01
subsystem: backend
tags: [merge, git, conflict-resolution, permissions, whatsapp, presence, schema]
dependency_graph:
  requires: []
  provides: [merge-in-progress, backend-conflicts-resolved]
  affects: [Plan 02 (frontend conflicts), Plan 03 (migrations)]
tech_stack:
  added: []
  patterns: [git-merge-strategy, keep-both-approaches]
key_files:
  created: []
  modified:
    - app/controllers/api/v1/accounts/conversations_controller.rb
    - app/models/channel/whatsapp.rb
    - config/schedule.yml
    - db/schema.rb
decisions:
  - "Keep BOTH upstream authorize @conversation and custom PermissionFilterService — complementary not conflicting"
  - "Whatsapp: keep both after_commit (upstream) and after_update phone change callback (custom)"
  - "schedule.yml: accept all upstream jobs and append custom activity_based_presence_job"
  - "schema.rb: keep upstream assignee_agent_bot_id column AND custom indexes from HEAD"
  - "corrupted conversation handling: already in message.rb (contact_inbox nil check), NOT conversation.rb"
metrics:
  duration_minutes: 4
  tasks_completed: 3
  files_modified: 4
  completed_date: "2026-02-21"
---

# Phase 01 Plan 01: Git Merge v4.11.1 Backend Conflicts Summary

**One-liner:** Git merge v4.11.1 initiated with backup branch; backend/config conflicts resolved preserving both upstream Pundit authorize fix and custom PermissionFilterService.

## What Was Built

Executed `git merge v4.11.1 --no-commit` on the `v4.7.0-custom` branch, identified all 11 conflict files, and resolved the 4 backend/config conflicts while keeping all custom modifications. The merge is in progress — 7 frontend/branding conflicts remain for Plan 02.

## Tasks Completed

| Task | Name | Status | Key Actions |
|------|------|--------|-------------|
| 1 | Create backup branch and execute git merge | Done | Backup `v4.7.0-custom-backup` created; merge initiated; 11 conflicts identified |
| 2 | Resolve backend and config merge conflicts | Done | 4 files resolved: conversations_controller.rb, whatsapp.rb, schedule.yml, schema.rb |
| 3 | Verify custom code survived in auto-merged files | Done | ActivityBasedPresence jobs intact; corrupted data fix in message.rb confirmed |

## Conflicts Resolved (4 of 11)

### 1. app/controllers/api/v1/accounts/conversations_controller.rb (CRITICAL)

- **Our side:** `authorize @conversation.inbox, :show?` + custom `check_conversation_permission!` using `PermissionFilterService`
- **Their side:** `authorize @conversation, :show?` (Pundit fix from commit 9898ccee9)
- **Resolution:** Kept both — changed to `authorize @conversation, :show?` (upstream Pundit fix) AND preserved `check_conversation_permission!` method with PermissionFilterService
- **Result:** Defense-in-depth: Pundit policy check + service-level filtering

### 2. app/models/channel/whatsapp.rb

- **Our side:** `after_update :sync_webhook_on_phone_number_change` callback
- **Their side:** `after_commit :setup_webhooks, on: :create, if: :should_auto_setup_webhooks?` with new `should_auto_setup_webhooks?` predicate
- **Resolution:** Kept both callbacks — `after_commit` for new record setup, `after_update` for phone number changes; added upstream `should_auto_setup_webhooks?` method

### 3. config/schedule.yml

- **Our side:** `activity_based_presence_job` cron entry
- **Their side:** Three new jobs: `periodic_assignment_job`, `remove_old_notification_job`, `remove_orphan_conversations_job`
- **Resolution:** Accepted all 3 upstream jobs, appended our custom `activity_based_presence_job` at end

### 4. db/schema.rb

- **Our side:** Two custom indexes: `idx_conversations_assignee_account` and `idx_conversations_response_time`
- **Their side:** New column `assignee_agent_bot_id` on conversations table
- **Resolution:** Kept upstream column AND both custom indexes (all are compatible)

## Conflicts Remaining (7 — for Plan 02)

- `app/javascript/dashboard/api/inboxes.js` (WhatsApp config)
- `app/javascript/dashboard/i18n/locale/pt_BR/inboxMgmt.json` (translations)
- `app/javascript/dashboard/routes/dashboard/settings/inbox/settingsPage/ConfigurationPage.vue` (WhatsApp UI)
- `app/javascript/dashboard/store/modules/inboxes.js` (WhatsApp store)
- `public/brand-assets/logo.svg` (white-label)
- `public/brand-assets/logo_dark.svg` (white-label)
- `theme/colors.js` (white-label)

## Custom Code Verification

| Custom Feature | File | Status | Notes |
|----------------|------|--------|-------|
| Corrupted conversation fix | `app/models/message.rb` | Intact | `contact_inbox.present?` guard at line 164 |
| PermissionFilterService | `conversations_controller.rb` | Intact | `check_conversation_permission!` preserved |
| Activity-Based Presence Job | `app/jobs/activity_based_presence_job.rb` | Intact | Auto-merged correctly |
| Update Agent Presence Job | `app/jobs/update_agent_presence_job.rb` | Intact | Auto-merged correctly |
| ActivityPresence migrations | `db/migrate/20250118*` | Intact | Two migration files survived |
| Activity cron schedule | `config/schedule.yml` | Intact | `activity_based_presence_job` preserved |

### Finding: No Ruby code for presence in account.rb/user.rb

The plan's verification check for `activity_based_presence` in account.rb/user.rb applies only to schema comments (generated by `annotate`), not to Ruby code. Commit 962cccc5a added the feature via migration files and job files, not via model methods. The auto-merged account.rb and user.rb are correct — they reflect the upstream merged versions with our schema comments.

### Finding: No "corrupted" keyword in conversation.rb

The plan's check for `corrupted` in conversation.rb was incorrect. Commit d237b1f42 only modified `message.rb` and `conversations_controller.rb`. The `conversation.rb` file was never modified by our custom commits. The corrupted handling is properly in `message.rb` at line 164.

## Deviations from Plan

### Auto-fixed Issues

None — plan executed as written.

### Clarifications

**1. [Clarification] Partial merge commit not possible**
- **Issue:** Git cannot commit a partial merge state. The merge commit will be made in Plan 02 after all 11 conflicts are resolved.
- **Impact:** Plan 01 has no git commit hash — the work is staged but the merge commit is pending.
- **Plan 02 dependency:** Plan 02 must resolve remaining 7 conflicts and then execute `git commit` to complete the merge.

**2. [Clarification] conversation.rb / user.rb "activity_based_presence" verification**
- **Plan said:** `grep -c 'activity_based_presence' app/models/account.rb` should return ≥ 1
- **Reality:** Returns 2 (only in schema comments, not Ruby code) — but there are no model methods to verify
- **Assessment:** The custom activity-based presence code lives in job files and migration files, all of which survived correctly

## Decisions Made

| Decision | Rationale |
|----------|-----------|
| Keep BOTH authorize approaches in conversations_controller | Defense-in-depth: Pundit policy + service-level filter are complementary |
| Keep both whatsapp callbacks | `after_commit` for new setup, `after_update` for phone number sync — different triggers |
| Append activity_based_presence_job to schedule.yml | Upstream jobs are additive, not replacements for our custom job |
| Keep custom indexes in schema.rb alongside upstream column | Both are correct; schema will be regenerated by `rails db:schema:dump` after migrations |

## Self-Check

### Files verified:

- [x] `app/controllers/api/v1/accounts/conversations_controller.rb` — no conflict markers, both authorize and PermissionFilterService present
- [x] `app/models/channel/whatsapp.rb` — no conflict markers, both callbacks present
- [x] `config/schedule.yml` — no conflict markers, activity_based_presence_job present
- [x] `db/schema.rb` — no conflict markers, upstream column present
- [x] `app/models/message.rb` — corrupted data nil check intact
- [x] `app/jobs/activity_based_presence_job.rb` — file exists
- [x] `app/jobs/update_agent_presence_job.rb` — file exists
- [x] `db/migrate/20250118000000_add_activity_based_presence_to_accounts.rb` — file exists
- [x] `db/migrate/20250118000001_set_auto_offline_to_true.rb` — file exists

### Git state:
- v4.7.0-custom-backup branch: exists
- Merge in progress: 7 frontend/branding conflicts remain (expected, for Plan 02)
- 4 backend/config conflict files: staged (resolved)
- 2181 auto-merged files: staged

## Self-Check: PASSED
