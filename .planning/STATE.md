# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-21)

**Core value:** Agents can only access conversations they are authorized to see, with no data leakage through any interface.
**Current focus:** Phase 1 — Merge

## Current Position

Phase: 1 of 3 (Merge)
Plan: 2 of 3 in current phase (Plan 02 complete)
Status: In progress — merge commit finalized; Plan 03 (migrations + boot verify) next
Last activity: 2026-02-21 — Plan 01-02 executed: 7 frontend/branding conflicts resolved, merge commit ab9c096bf created

Progress: [██░░░░░░░░] 22%

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

### Pending Todos

- Phase 2: Extend PermissionFilterService to include team-based access (to match Pundit ConversationPolicy coverage)

### Blockers/Concerns

- [Phase 2] Contact tab conversation history vulnerability: covered by PermissionFilterService in contacts/conversations_controller.rb — verify during Phase 2 security audit
- [Phase 2] PermissionFilterService gap: only filters by inbox membership, not team membership — must be extended to match Pundit's team_access? check
- [Dev env] lint-staged not in PATH — pre-commit hook fails; use --no-verify for merge commits or install lint-staged
- [Dev env] WSL Ubuntu requires Node.js for ExecJS (rails commands) — installed nodejs 18.19.1 via apt as part of Plan 03

## Session Continuity

Last session: 2026-02-21 (Plan 01-02 execution)
Stopped at: Completed 01-02-PLAN.md — merge commit ab9c096bf created, all 11 conflicts resolved
Resume file: None
