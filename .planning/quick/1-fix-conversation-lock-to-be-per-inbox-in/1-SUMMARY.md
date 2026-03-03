---
task: 1
description: "Fix conversation lock to be per-inbox instead of platform-wide"
status: completed
commits:
  - hash: 3378e3554
    message: "fix(conversations): scope lock_to_single_conversation to non-resolved conversations per inbox"
  - hash: abfe25ac9
    message: "fix(conversations): scope incoming message services to non-resolved conversations"
---

## Summary

Fixed the `lock_to_single_conversation` feature so it only prevents multiple **non-resolved** conversations per contact per inbox, instead of blocking conversation creation platform-wide.

### Problem

When `lock_to_single_conversation` was enabled, the system used `.conversations.last` which returned ANY conversation (including resolved ones). This meant:
- Operators couldn't create new conversations for contacts who had **resolved** conversations
- A contact couldn't have open conversations in different inboxes simultaneously
- WebWidget inboxes disappeared from the "New Conversation" dropdown once any conversation existed

### Fix

Changed all conversation lookup paths to use `.where.not(status: :resolved).last`, ensuring only open/pending/snoozed conversations block new conversation creation.

### Files Modified

**Task 1 — Core builders + specs (commit 3378e355):**
- `app/builders/conversation_builder.rb` — `look_up_exising_conversation` now excludes resolved
- `app/services/contacts/contactable_inboxes_service.rb` — `website_contactable_inbox` shows inbox when all conversations resolved
- `spec/builders/conversation_builder_spec.rb` — Added specs for resolved pass-through and cross-inbox isolation
- `spec/services/contacts/contactable_inboxes_service_spec.rb` — Added spec for resolved conversation scenario

**Task 2 — Incoming message services (commit abfe25ac9):**
- `app/services/whatsapp/incoming_message_base_service.rb`
- `app/services/twilio/incoming_message_service.rb`
- `app/services/telegram/incoming_message_service.rb`
- `app/services/sms/incoming_message_service.rb`
- `app/builders/messages/facebook/message_builder.rb`
- `app/builders/messages/instagram/base_message_builder.rb`

### Behavior After Fix

| Scenario | Before | After |
|----------|--------|-------|
| Contact has resolved conv in Inbox A, operator creates new in Inbox A | Blocked | Allowed |
| Contact has open conv in Inbox A, operator creates new in Inbox B | Blocked | Allowed |
| Contact has open conv in Inbox A, operator creates new in Inbox A | Blocked | Blocked (correct) |
| Incoming message to channel with all resolved convs | Appended to resolved conv | New conversation created |
