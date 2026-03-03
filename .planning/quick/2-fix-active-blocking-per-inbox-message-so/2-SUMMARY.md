---
phase: quick-2
plan: 1
subsystem: conversations, contacts, bulk-actions
tags: [lock-to-single-conversation, incoming-message-services, contacts-sort, bulk-actions, mark-as-unread]
dependency_graph:
  requires: []
  provides:
    - "Active-conversation-aware lock logic for WhatsApp, Twilio, Telegram, SMS, Facebook, Instagram, ConversationBuilder"
    - "Contact sort menu without last_activity_at option, defaulting to name"
    - "Bulk mark-as-unread action end-to-end (backend + frontend)"
  affects:
    - "All incoming message services"
    - "Contacts list UI"
    - "Conversation bulk actions bar"
tech_stack:
  added: []
  patterns:
    - "ActiveRecord joins(:messages).where(messages: { message_type: :outgoing }) for operator-activity check"
    - "BulkActionsJob action_name dispatch pattern for custom bulk operations"
key_files:
  created: []
  modified:
    - app/services/whatsapp/incoming_message_base_service.rb
    - app/services/twilio/incoming_message_service.rb
    - app/services/telegram/incoming_message_service.rb
    - app/services/sms/incoming_message_service.rb
    - app/builders/messages/facebook/message_builder.rb
    - app/builders/messages/instagram/base_message_builder.rb
    - app/builders/conversation_builder.rb
    - app/javascript/dashboard/components-next/Contacts/ContactsHeader/components/ContactSortMenu.vue
    - app/javascript/dashboard/routes/dashboard/contacts/pages/ContactsIndex.vue
    - app/jobs/bulk_actions_job.rb
    - app/javascript/dashboard/composables/chatlist/useBulkActions.js
    - app/javascript/dashboard/components/widgets/conversation/conversationBulkActions/Index.vue
    - app/javascript/dashboard/components/ChatList.vue
    - app/javascript/dashboard/i18n/locale/en/bulkActions.json
decisions:
  - "Use joins(:messages).where(messages: { message_type: :outgoing }) rather than a separate query — keeps logic inline and uses existing AR associations"
  - "BulkActionsJob.bulk_mark_as_unread uses update_columns (skips callbacks/validations) to match existing unread endpoint behavior"
  - "Removed last_activity_at from sort menu entirely rather than just changing default — prevents users from selecting a sort that no longer reflects operator intent"
metrics:
  duration: 3 min
  completed_date: "2026-03-03"
  tasks_completed: 3
  files_modified: 14
---

# Quick Task 2: Fix Active Blocking per Inbox (Message Services + Contact Sort + Bulk Unread) Summary

**One-liner:** Operator-reply-aware lock_to_single_conversation across all channels, alphabetical-default contacts sort, and bulk mark-as-unread action.

## Objective

Three related workflow improvements:
1. Redefine "active" for `lock_to_single_conversation` — only reuse conversations where an operator has replied
2. Default contacts sort to alphabetical (by name) and remove the `last_activity_at` sort option
3. Add batch "mark as unread" to conversation bulk actions

## Tasks Completed

| Task | Name | Commit | Files Changed |
|------|------|--------|---------------|
| 1 | Redefine lock_to_single_conversation to require operator activity | 2c3c585f3 | 7 backend files |
| 2 | Default contacts sort to name, remove last_activity_at option | e06f7ae75 | 2 frontend files |
| 3 | Add batch mark-as-unread for conversations | 362a66a6f | 5 files |

## What Was Done

### Task 1: Operator-Activity-Aware Lock

All 7 incoming message services/builders that implement the `lock_to_single_conversation` logic now require at least one outgoing (operator) message before reusing an existing conversation. Without an operator reply, a new conversation is created.

**Before:** `@contact_inbox.conversations.last` — reused ANY conversation regardless of whether operator replied.

**After:**
```ruby
@contact_inbox.conversations
              .joins(:messages)
              .where(messages: { message_type: :outgoing })
              .order(created_at: :desc)
              .first
```

Files changed:
- `app/services/whatsapp/incoming_message_base_service.rb`
- `app/services/twilio/incoming_message_service.rb`
- `app/services/telegram/incoming_message_service.rb`
- `app/services/sms/incoming_message_service.rb`
- `app/builders/messages/facebook/message_builder.rb`
- `app/builders/messages/instagram/base_message_builder.rb`
- `app/builders/conversation_builder.rb`

### Task 2: Contact Sort Defaults

- `ContactSortMenu.vue`: Removed the `last_activity_at` entry from `sortMenus` array. Updated default `activeSort` prop from `'last_activity_at'` to `'name'`.
- `ContactsIndex.vue`: Changed `DEFAULT_SORT_FIELD` constant from `'last_activity_at'` to `'name'`.

### Task 3: Bulk Mark-as-Unread

**Backend (`bulk_actions_job.rb`):** Added `bulk_mark_as_unread` method called from `bulk_update`. When `action_name == 'mark_as_unread'`, iterates over selected conversations and sets `agent_last_seen_at` and `assignee_last_seen_at` to 1 second before the last incoming message.

**Frontend:**
- `useBulkActions.js`: Added `onMarkAsUnread` function that dispatches `bulkActions/process` with `action_name: 'mark_as_unread'`.
- `ConversationBulkActions/Index.vue`: Added `markAsUnread` emit, `markAsUnread()` method, and a new `NextButton` with `i-lucide-mail` icon as the first action button.
- `ChatList.vue`: Destructures `onMarkAsUnread` from `useBulkActions()` and wires `@mark-as-unread="onMarkAsUnread"` on `<ConversationBulkActions>`.
- `bulkActions.json`: Added `MARK_AS_UNREAD` keys (`TOOLTIP`, `SUCCESS`, `FAILED`).

## Deviations from Plan

None — plan executed exactly as written.

## Self-Check: PASSED

All files verified present. All commits verified in git log:
- `2c3c585f3` — Task 1: operator-activity lock
- `e06f7ae75` — Task 2: contacts sort defaults
- `362a66a6f` — Task 3: bulk mark-as-unread
