---
status: verifying
trigger: "conversation-visibility-leak — INBOX VIEW route still shows other agents' conversations"
created: 2026-02-24T01:00:00Z
updated: 2026-02-24T01:20:00Z
symptoms_prefilled: true
---

## Current Focus

hypothesis: CONFIRMED AND FIXED
test: Code trace + JOIN-based SQL filter applied in NotificationFinder
expecting: Magna sees only her own + unassigned conversations in inbox-view
next_action: Archive and commit

## Symptoms

expected: When agent Magna clicks "Caixa de Entrada" (inbox view), she should only see her own conversations + unassigned ones
actual: Magna sees ALL conversations in the inbox, including those assigned to Cintia.Machado
errors: No errors — conversations just appear when they shouldn't
reproduction: 1) Log in as agent Magna 2) Click "Conversas" menu — CORRECT (only shows own + unassigned) 3) Click "Caixa de Entrada" (inbox view) — BUG (shows all conversations including Cintia's)
timeline: PermissionFilterService fix (commit 6f6e47967) fixed the Conversations menu path, but inbox-view uses NotificationFinder which was never addressed

## Eliminated

- hypothesis: "The inbox view uses ConversationFinder / PermissionFilterService"
  evidence: |
    InboxList.vue dispatches notifications/index store action → NotificationsAPI.get →
    GET /api/v1/accounts/:id/notifications → NotificationsController#index → NotificationFinder.
    Completely separate code path from ConversationFinder.
  timestamp: 2026-02-24T01:05:00Z

- hypothesis: "Notifications are per-user so filtering is already applied"
  evidence: |
    Notifications have user_id and are scoped to current_user, but conversation_creation
    notifications are created for ALL inbox members. Magna legitimately has notification records
    pointing to conversations assigned to Cintia. The fix must filter by conversation assignment.
  timestamp: 2026-02-24T01:08:00Z

## Evidence

- timestamp: 2026-02-24T01:05:00Z
  checked: app/javascript/dashboard/routes/dashboard/inbox/InboxList.vue
  found: |
    fetchNotifications() calls store.dispatch('notifications/index', filter)
    The 'index' action calls NotificationsAPI.get() which hits GET /api/v1/accounts/:id/notifications
  implication: The entire inbox view is driven by notifications, not conversations

- timestamp: 2026-02-24T01:05:00Z
  checked: app/javascript/dashboard/store/modules/notifications/actions.js
  found: |
    index action calls NotificationsAPI.get({ page, status, type, sortOrder })
    No conversation-assignment-based filtering on the frontend
  implication: Frontend passes no assignment filter — all filtering must be server-side

- timestamp: 2026-02-24T01:05:00Z
  checked: app/controllers/api/v1/accounts/notifications_controller.rb
  found: |
    index action uses NotificationFinder.new(Current.user, Current.account, params)
    No additional filtering applied in the controller
  implication: NotificationFinder is the sole server-side gating mechanism

- timestamp: 2026-02-24T01:05:00Z
  checked: app/finders/notification_finder.rb (BEFORE fix)
  found: |
    find_all_notifications: current_user.notifications.where(account_id: ...)
    Only filtered by snoozed_until and read_at
    NO filtering by conversation assignment
  implication: Every unread notification appears in the inbox view regardless of who the conversation is assigned to

- timestamp: 2026-02-24T01:08:00Z
  checked: app/listeners/notification_listener.rb
  found: |
    conversation_created event: conversation.inbox.members.each → create conversation_creation notification for every agent
    This is why Magna has notifications pointing to Cintia's conversations
  implication: Basic agents accumulate notifications for ALL conversations in their inboxes, not just their own

- timestamp: 2026-02-24T01:08:00Z
  checked: app/builders/notification_builder.rb
  found: |
    For conversation_creation: only creates notification if user subscribed (email or push)
    If Magna has conversation_creation notifications enabled, she gets one per inbox conversation
  implication: The notification creation is working as designed — filtering must happen at read-time

## Resolution

root_cause: |
  The Inbox View (/inbox-view) uses NotificationFinder, completely separate from ConversationFinder.
  NotificationFinder fetches current_user.notifications but only filters by snoozed/read state.
  Since conversation_creation notifications are sent to ALL inbox members, Magna has notification
  records pointing to conversations assigned to Cintia. The previous PermissionFilterService fix
  did not affect this path at all — NotificationFinder had zero assignment-based filtering.

fix: |
  Modified app/finders/notification_finder.rb:
  - Added basic_agent? check: role == 'agent' AND custom_role_id blank (same as PermissionFilterService)
  - Added filter_by_assignment_for_basic_agents: JOIN notifications to conversations table,
    filter to conversations where assignee_id IS NULL OR assignee_id = current_user.id
  - Called in set_up after find_all_notifications, before snoozed/read filters
  - Administrators are unaffected (basic_agent? returns false)
  - Custom-role agents are unaffected (custom_role_id.present? → basic_agent? returns false)

  SQL added for basic agents:
    INNER JOIN conversations ON conversations.id = notifications.primary_actor_id
      AND notifications.primary_actor_type = 'Conversation'
    WHERE conversations.assignee_id IS NULL OR conversations.assignee_id = [user_id]

verification: |
  Code analysis verified:
  - Administrator path: basic_agent? = false → no JOIN applied → all notifications visible
  - Custom-role agent: basic_agent? = false → no JOIN applied → enterprise handles separately
  - Basic agent: JOIN applied → only unassigned + own conversations visible in inbox
  - Existing tests: all use unassigned conversations by default → JOIN condition is assignee_id IS NULL
    → tests pass unchanged
  - New spec tests: added 3 tests for basic agent filtering + 1 test for administrator bypass

files_changed:
  - app/finders/notification_finder.rb
  - spec/finders/notification_finder_spec.rb
