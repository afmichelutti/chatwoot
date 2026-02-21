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
| Git merge over rebase | 324 upstream commits, merge is safer and preserves history | -- Pending |
| Evaluate upstream permission fix vs custom PermissionFilterService | Upstream uses Pundit authorize, our fix uses service filter — need to determine which covers more vectors | -- Pending |
| Security audit scope: all endpoints | Contact history, search, filters, direct URL access — not just conversations controller | -- Pending |

---
*Last updated: 2026-02-21 after milestone v4.11.1 Upgrade & Security Audit started*
