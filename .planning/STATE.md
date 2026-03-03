# Project State

## Project Reference

See: .planning/PROJECT.md (updated 2026-02-21)

**Core value:** Agents can only access conversations they are authorized to see, with no data leakage through any interface.
**Current focus:** Phase 1 — Merge

## Current Position

Phase: 1 of 3 (Merge) — COMPLETE
Plan: 3 of 3 in current phase — COMPLETE (all 3 plans finished)
Status: Phase 1 complete — ready for Phase 2 (Security Audit)
Last activity: 2026-03-03 - Completed quick task 1: Fix conversation lock to be per-inbox instead of platform-wide

Progress: [████░░░░░░] 33% (Phase 1 complete: 3/3 plans, 3 phases total)

## Performance Metrics

**Velocity:**
- Total plans completed: 2
- Average duration: 9.5 min
- Total execution time: 0.3 hours

**By Phase:**

| Phase | Plans | Total | Avg/Plan |
|-------|-------|-------|----------|
| Phase 1 (Merge) | 3/3 | 64 min | 21.3 min |

*Updated after each plan completion*
| Phase 01 P02 | 15 | 2 tasks | 7 files |
| Phase 01 P03 | 45 | 3 tasks | 3 files |

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

### Quick Tasks Completed

| # | Description | Date | Commit | Directory |
|---|-------------|------|--------|-----------|
| 1 | Fix conversation lock to be per-inbox instead of platform-wide | 2026-03-03 | abfe25ac9 | [1-fix-conversation-lock-to-be-per-inbox-in](./quick/1-fix-conversation-lock-to-be-per-inbox-in/) |

## Session Continuity

Last session: 2026-02-21 (Plan 01-03 completion)
Stopped at: Phase 1 complete — all 3 plans finished. Phase 2 (Security Audit) ready to begin.
Resume file: None
