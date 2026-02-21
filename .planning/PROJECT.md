# Chatwoot Fork — ivox

## What This Is

A customized fork of Chatwoot (open-source customer support platform) maintained by ivox. The fork is based on v4.7.0 with custom modifications for agent permission enforcement, activity-based presence, white-label branding, WhatsApp Cloud API configuration, and corrupted conversation handling. Used in production for WhatsApp-based customer support operations.

## Core Value

Agents can only access conversations they are authorized to see, with no data leakage through any interface (contacts, search, filters, direct URL access).

## Current Milestone: v4.11.1 Upgrade & Security Audit

**Goal:** Upgrade fork to latest Chatwoot v4.11.1 and ensure complete agent conversation isolation

**Target features:**
- Merge upstream v4.11.1 (324 new commits) without losing custom changes
- Validate and harden agent conversation isolation across all access vectors
- Resolve merge conflicts, especially in permission-related code
- Run migrations and verify system stability

## Requirements

### Validated

- Activity-Based Presence system (custom, v4.7.0-custom)
- White-label branding customization (custom, v4.7.0-custom)
- WhatsApp Cloud API config management (custom, v4.7.0-custom)
- Corrupted conversation handling (custom, v4.7.0-custom)
- Permission checks on conversation access (custom, v4.7.0-custom)

### Active

- [ ] Upgrade to Chatwoot v4.11.1 via merge
- [ ] Preserve all custom modifications through upgrade
- [ ] Agent conversation isolation — no data leakage via any endpoint
- [ ] Contact history filtered by agent permissions
- [ ] Prevent agents from reassigning other agents' conversations
- [ ] All endpoints enforce permission checks at API level

### Out of Scope

- New feature development — this milestone is upgrade + security only
- ChatWize (Next.js project) — deferred, separate project
- Channel additions — no new channels in this milestone
- UI redesign — preserve existing customizations

## Context

**Fork state (2026-02-21):**
- Current: `v4.7.0-custom` branch, 13 custom commits on v4.7.0
- Target: `v4.11.1` (324 commits ahead)
- Repo: origin=afmichelutti/chatwoot, upstream=chatwoot/chatwoot
- Strategy: `git merge v4.11.1`

**Custom commits to preserve:**
1. `962cccc5a` — Activity-Based Presence system and custom configs
2. `d237b1f42` — Corrupted conversations fix + permission enforcement
3. `90584ec15` — White label customization and branding
4. `7355cf545` — WhatsApp Cloud API config management and i18n
5. Dev scripts: start-chatwoot.bat, stop-chatwoot.bat, setup-dev.sh
6. i18n: pt_BR translations for inbox management and general settings

**Upstream permission fix (already in v4.11.1):**
Commit `9898ccee9` changed `authorize @conversation.inbox, :show?` to `authorize @conversation, :show?` in conversations controller. This is a different approach than our custom `PermissionFilterService` — need to evaluate which is more comprehensive.

**Known vulnerability (our discovery):**
Agents could view ALL conversations via Contacts tab → conversation history, bypassing permission checks. Could also reassign conversations from other agents to themselves. Our custom fix used `PermissionFilterService` but may not cover all vectors.

**Tech Stack:**
- Ruby on Rails 7.x (upgraded to 7.2.2 in upstream)
- Vue.js 3 (frontend)
- PostgreSQL
- Redis + Sidekiq (background jobs)

## Constraints

- **Zero data loss**: All custom modifications must survive the merge
- **Security first**: Permission audit must cover ALL endpoints, not just conversations controller
- **Merge strategy**: Git merge (not rebase) — preserves commit history
- **Testing**: Must verify system boots and core flows work after merge
- **Backward compatibility**: Existing data/migrations must remain intact

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Git merge over rebase | 324 upstream commits, merge is safer and preserves history | Git merge strategy used; merge commit ab9c096bf |
| Upstream permission fix vs custom PermissionFilterService | Two complementary mechanisms serving different purposes | **Both** — Pundit `authorize @conversation, :show?` + `PermissionFilterService` (see details below) |
| Security audit scope: all endpoints | Contact history, search, filters, direct URL access — not just conversations controller | Phase 2 will audit all vectors |

### Permission Approach Decision (Plan 03 — 2026-02-21)

**Decision: Keep BOTH upstream Pundit `authorize @conversation, :show?` AND custom `Conversations::PermissionFilterService`**

**Analysis of each approach:**

**Upstream Pundit `authorize @conversation, :show?`** (ConversationPolicy#show?):
- Checks: `administrator? || agent_bot? || agent_can_view_conversation?`
- `agent_can_view_conversation?` = `inbox_access? || team_access?`
- Covers: An agent who is assigned to the conversation's inbox OR team
- Scope: Applied on single-resource actions (show, update, destroy, toggle_status, etc.)
- Mechanism: Policy check after conversation is loaded — denies access to the individual record

**Custom `Conversations::PermissionFilterService`**:
- Filters: `conversations.where(inbox: user.inboxes.where(account_id: account.id))`
- Note: Only filters by inbox membership — does NOT cover team-only access
- Scope: Applied on collection endpoints (index via conversation_finder, search, filter) AND as double-check on individual access (check_conversation_permission!)
- Applied in: `conversations_controller.rb`, `contacts/conversations_controller.rb`, `conversation_finder.rb`, `filter_service.rb`
- Mechanism: Collection-level scoping — prevents data appearing in lists even if inbox membership check passes

**Why Both:**
- Defense-in-depth: If Pundit fails, PermissionFilterService blocks collection access. If PermissionFilterService is too restrictive (team-only members), Pundit allows their individual access.
- Different coverage: Pundit covers team-based access (team_access?), PermissionFilterService covers only inbox-based access — they cover different authentication axes
- Phase 2 Security Audit will reconcile the gap: PermissionFilterService should be extended to also check team access to match Pundit's coverage

**Recommended Phase 2 action:** Update `PermissionFilterService#accessible_conversations` to include team-based access: `conversations.where(inbox: user.inboxes...).or(conversations.where(team: user.teams...))` — then both mechanisms will have consistent coverage.

---
*Last updated: 2026-02-21 — Plan 03 permission decision recorded*
