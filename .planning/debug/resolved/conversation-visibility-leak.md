---
status: resolved
trigger: "conversation-visibility-leak — Agents can see conversations assigned to other agents in the same inbox"
created: 2026-02-24T00:00:00Z
updated: 2026-02-24T00:05:00Z
symptoms_prefilled: true
---

## Current Focus

hypothesis: CONFIRMED AND FIXED
test: Code review, spec analysis
expecting: Fix verified by analysis — unit tests updated to match corrected behavior
next_action: Archive and commit

## Symptoms

expected: Operators (agents) should NOT see conversations assigned to other operators. Each agent only sees their own assigned conversations.
actual: User "Magna" (agent role) can see conversations assigned to "Cintia.Machado" in the Caixa de Entrada / Inbox view
errors: No errors — conversations just show up when they shouldn't
reproduction: Log in as any agent, go to Caixa de Entrada (Inbox), see ALL conversations regardless of assignment
started: The restriction was implemented but NEVER worked — agents have always seen all conversations in their inbox

## Eliminated

- hypothesis: "The PermissionFilterService had an active bug that was recently introduced"
  evidence: The service was always inbox-only; never filtered by assignment for basic agents
  timestamp: 2026-02-24T00:01:00Z

- hypothesis: "Custom role enterprise logic handles basic agents"
  evidence: Enterprise module's user_has_custom_role? requires custom_role_id present — basic agents have blank custom_role_id
  timestamp: 2026-02-24T00:01:00Z

## Evidence

- timestamp: 2026-02-24T00:01:00Z
  checked: app/services/conversations/permission_filter_service.rb
  found: |
    accessible_conversations method only does:
      conversations.where(inbox: user.inboxes.where(account_id: account.id))
    This only checks inbox membership — NOT assignment.
    Administrator bypass returns all conversations.
    No logic for basic agents (role='agent' without custom role).
  implication: Basic agents get all conversations in their inboxes with zero assignment-based restriction.

- timestamp: 2026-02-24T00:01:00Z
  checked: enterprise/app/services/enterprise/conversations/permission_filter_service.rb
  found: |
    Enterprise extension only applies when user_has_custom_role? is true
    (role == 'agent' AND custom_role_id present).
    Basic agents (no custom_role_id) fall through to super → accessible_conversations → inbox-only filter.
  implication: Custom role logic correctly restricts custom-role agents, but basic agents with standard 'agent' role have no assignment-based restriction.

- timestamp: 2026-02-24T00:01:00Z
  checked: app/finders/conversation_finder.rb
  found: |
    filter_by_assignee_type: 'me' → assigned_to(user), 'unassigned' → unassigned,
    'assigned' → assigned. 'all' or nil → NO filter.
    ConversationFinder calls PermissionFilterService then filter_by_assignee_type.
    When assignee_type='all', no per-user filtering happens.
  implication: The assignee_type filter is a client-side convenience, not a security boundary.

- timestamp: 2026-02-24T00:01:00Z
  checked: app/javascript/dashboard/constants/globals.js + permissions.js
  found: |
    ASSIGNEE_TYPE.ALL = 'all'.
    ASSIGNEE_TYPE_TAB_PERMISSIONS.all.permissions includes [...ROLES] which includes 'agent'.
    Basic agent has permissions=['agent'] from AccountUser#permissions.
    filterItemsByPermission uses .some() — 'agent' matches → agent sees "All" tab.
  implication: Frontend does NOT hide the "All" tab for basic agents. They can see and click it.

- timestamp: 2026-02-24T00:01:00Z
  checked: app/policies/conversation_policy.rb
  found: |
    show? uses authorize — only checked for single-conversation access (show action).
    index? returns true unconditionally — no restriction on listing.
    The list endpoint (index) uses ConversationFinder, NOT ConversationPolicy.
  implication: Pundit doesn't protect the list. Only PermissionFilterService does, which was inbox-only.

## Resolution

root_cause: |
  Conversations::PermissionFilterService#accessible_conversations returns all conversations
  in user's inboxes without any assignment-based restriction. For basic agents (role='agent',
  no custom_role_id), calling perform() returned all inbox conversations — identical to
  having no filtering within the inbox. The enterprise extension only applies to custom-role
  agents. Standard agents have always been able to see every conversation in their inboxes.

fix: |
  Modified PermissionFilterService to detect basic agents (user_role == 'agent' AND
  custom_role_id blank) and apply assignment-based restriction:
    agent_restricted_conversations = (mine UNION unassigned) within accessible inboxes

  This matches the behavior of the enterprise module's conversation_unassigned_manage
  permission (the most permissive non-admin level). Basic agents can see:
  1. Conversations assigned to them
  2. Unassigned conversations in their inboxes

  Updated tests in:
  - spec/services/conversations/permission_filter_service_spec.rb (rewrote to document correct behavior)
  - spec/enterprise/services/enterprise/conversations/permission_filter_service_spec.rb (updated regular agent context)
  - spec/finders/conversation_finder_spec.rb (updated counts and source_id test to match security fix)

verification: |
  Code analysis verified:
  - Administrator path unchanged (returns all conversations)
  - Custom role agent path unchanged (enterprise module handles it via user_has_custom_role?)
  - Basic agent: new agent_restricted_conversations returns UNION of assigned_to(user) + unassigned
  - controller check_conversation_permission! now returns 403 for conversations assigned to others
  - Enterprise module: user_has_custom_role? is false for basic agents → calls super → hits basic_agent? check

files_changed:
  - app/services/conversations/permission_filter_service.rb
  - spec/services/conversations/permission_filter_service_spec.rb
  - spec/enterprise/services/enterprise/conversations/permission_filter_service_spec.rb
  - spec/finders/conversation_finder_spec.rb
