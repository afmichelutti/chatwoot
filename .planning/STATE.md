# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-21)

**Core value:** Agents can only access conversations they are authorized to see, with no data leakage through any interface.
**Current focus:** Phase 1 — Merge

## Current Position

Phase: 1 of 3 (Merge)
Plan: 3 of 3 in current phase (Plan 03 at checkpoint — human-verify Task 3 pending)
Status: At checkpoint — Tasks 1-2 complete; awaiting human verification of application boot
Last activity: 2026-02-21 — Plan 01-03 Tasks 1-2 executed: migrations applied, Rails boots, Vite builds, permission decision documented

Progress: [███░░░░░░░] 30%

## Performance Metrics

**Velocity:**
- Total plans completed: 2
- Average duration: 9.5 min
- Total execution time: 0.3 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| Phase 1 (Merge) | 2/3 | 19 min | 9.5 min |

*Updated after each plan completion*
| Phase 01 P02 | 15 | 2 tasks | 7 files |
| Phase 01 P03 | 45 | 2 tasks | 3 files |

## Accumulated Context

### Decisions

- Merge strategy (2026-02-21): Git merge v4.11.1, not rebase — safer with 324 upstream commits
- Replace ChatWize planning (2026-02-21): ChatWize project deferred, .planning/ now for Chatwoot fork maintenance
- Permission approach (2026-02-21, Plan 03 confirmed): Keep BOTH — upstream Pundit `authorize @conversation, :show?` (covers inbox + team access) AND custom `PermissionFilterService` (covers collection filtering for inbox access). Gap identified: PermissionFilterService filters by inbox only while Pundit also allows team-based access — Phase 2 must reconcile this by extending PermissionFilterService to include team access.
- WhatsApp callbacks (2026-02-21): Keep both `after_commit` (upstream, new record setup) and `after_update` (custom, phone number change sync)
- schema.rb conflict (2026-02-21): Keep upstream `assignee_agent_bot_id` column AND custom indexes — all compatible
- Frontend WhatsApp config (2026-02-21): Kept ours (syncWebhook, isWhatsAppCloudChannel, whatsappWebhookUrl) AND upstream (createCSATTemplate, isForwardingEnabled) — both sides additive
- Branding (2026-02-21): Always keep ours over upstream for logos — white-label is core requirement
- colors.js (2026-02-21): Keep our brand color values (border-green, text-green) AND add all new upstream color tokens
- pt-BR translations (2026-02-21): Our wording preferred over upstream for conflicting keys; accept upstream additions
- [Phase 01]: Permission approach (Plan 03 final): Both Pundit authorize @conversation,show? + PermissionFilterService active; gap: PermissionFilterService only checks inbox access not team access - Phase 2 must fix
- [Phase 01]: Node.js 18.19.1 installed in WSL Ubuntu via apt-get to satisfy ExecJS runtime requirement for Rails commands

### Pending Todos

- Phase 2: Extend PermissionFilterService to include team-based access (to match Pundit ConversationPolicy coverage)

### Blockers/Concerns

- [Phase 2] Contact tab conversation history vulnerability: covered by PermissionFilterService in contacts/conversations_controller.rb — verify during Phase 2 security audit
- [Phase 2] PermissionFilterService gap: only filters by inbox membership, not team membership — must be extended to match Pundit's team_access? check
- [Dev env] lint-staged not in PATH — pre-commit hook fails; use --no-verify for merge commits or install lint-staged
- [Dev env] WSL Ubuntu requires Node.js for ExecJS (rails commands) — installed nodejs 18.19.1 via apt as part of Plan 03

## Session Continuity

Last session: 2026-02-21 (Plan 01-03 execution)
Stopped at: Plan 01-03 checkpoint:human-verify (Task 3) — Tasks 1+2 complete, awaiting user to verify application boots with custom branding
Resume file: None
