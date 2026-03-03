---
phase: quick
plan: 1
type: execute
wave: 1
depends_on: []
files_modified:
  - app/builders/conversation_builder.rb
  - app/services/contacts/contactable_inboxes_service.rb
  - app/services/whatsapp/incoming_message_base_service.rb
  - app/services/twilio/incoming_message_service.rb
  - app/services/telegram/incoming_message_service.rb
  - app/services/sms/incoming_message_service.rb
  - spec/builders/conversation_builder_spec.rb
  - spec/services/contacts/contactable_inboxes_service_spec.rb
autonomous: true
requirements: [CONV-LOCK-PER-INBOX]

must_haves:
  truths:
    - "Contact with a resolved conversation in Inbox A can have a new conversation created in Inbox A"
    - "Contact with an open conversation in Inbox A can have a new conversation created in Inbox B"
    - "Contact with an open conversation in Inbox A cannot have a second open conversation created in Inbox A when lock_to_single_conversation is enabled"
    - "WebWidget inboxes appear in contactable inboxes list when all conversations are resolved"
    - "Incoming messages to a channel with lock_to_single_conversation create new conversations after prior ones are resolved"
  artifacts:
    - path: "app/builders/conversation_builder.rb"
      provides: "Per-inbox lock scoped to non-resolved conversations only"
      contains: "where.not.*status.*resolved"
    - path: "app/services/contacts/contactable_inboxes_service.rb"
      provides: "WebWidget inbox available when all conversations resolved"
      contains: "where.not.*status.*resolved"
    - path: "app/services/whatsapp/incoming_message_base_service.rb"
      provides: "WhatsApp lock scoped to non-resolved conversations"
      contains: "where.not.*status.*resolved"
  key_links:
    - from: "app/builders/conversation_builder.rb"
      to: "conversations table"
      via: "contact_inbox.conversations scope"
      pattern: "where.not.*status.*resolved"
    - from: "app/services/contacts/contactable_inboxes_service.rb"
      to: "conversations table"
      via: "contact_inbox.conversations scope"
      pattern: "where.not.*status.*resolved"
---

<objective>
Fix the conversation lock behavior so that `lock_to_single_conversation` only prevents multiple OPEN conversations per contact per inbox, not across the entire platform. Currently, resolved conversations still block new conversation creation, and WebWidget inboxes disappear from the "New Conversation" inbox selector once any conversation exists (even resolved ones).

Purpose: Allow operators to create new conversations for contacts in any inbox, as long as there is no existing open/pending/snoozed conversation in that specific inbox.
Output: Modified backend services and builders with updated specs.
</objective>

<execution_context>
@C:/Users/afmic/.claude/get-shit-done/workflows/execute-plan.md
@C:/Users/afmic/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@app/builders/conversation_builder.rb
@app/services/contacts/contactable_inboxes_service.rb
@app/services/whatsapp/incoming_message_base_service.rb
@app/services/twilio/incoming_message_service.rb
@app/services/telegram/incoming_message_service.rb
@app/services/sms/incoming_message_service.rb
@spec/builders/conversation_builder_spec.rb
@spec/services/contacts/contactable_inboxes_service_spec.rb

<interfaces>
<!-- Key models and associations the executor needs to understand -->

From app/models/conversation.rb:
```ruby
enum status: { open: 0, resolved: 1, pending: 2, snoozed: 3 }
belongs_to :contact_inbox
belongs_to :inbox
belongs_to :contact
```

From app/models/contact_inbox.rb:
```ruby
has_many :conversations, dependent: :destroy_async
belongs_to :contact
belongs_to :inbox
```

From app/models/inbox.rb:
```ruby
# lock_to_single_conversation :boolean default(FALSE), not null
```

Current ConversationBuilder (the core bug):
```ruby
def look_up_exising_conversation
  return unless @contact_inbox.inbox.lock_to_single_conversation?
  @contact_inbox.conversations.last  # Returns ANY conversation, including resolved ones
end
```

Current ContactableInboxesService (WebWidget filtering bug):
```ruby
def website_contactable_inbox(inbox)
  latest_contact_inbox = inbox.contact_inboxes.where(contact: @contact).last
  return unless latest_contact_inbox
  return if latest_contact_inbox.conversations.present?  # Blocks if ANY conversation exists
  { source_id: latest_contact_inbox.source_id, inbox: inbox }
end
```

Current incoming message services pattern (WhatsApp, Twilio, Telegram, SMS):
```ruby
def set_conversation
  @conversation = if @inbox.lock_to_single_conversation
                    @contact_inbox.conversations.last  # Returns ANY conversation
                  else
                    @contact_inbox.conversations
                                  .where.not(status: :resolved).last
                  end
  # ... then creates conversation if nil
end
```
</interfaces>
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: Fix ConversationBuilder and ContactableInboxesService to scope lock per-inbox to non-resolved conversations</name>
  <files>
    app/builders/conversation_builder.rb
    app/services/contacts/contactable_inboxes_service.rb
    spec/builders/conversation_builder_spec.rb
    spec/services/contacts/contactable_inboxes_service_spec.rb
  </files>
  <behavior>
    ConversationBuilder:
    - When lock_to_single_conversation is true and contact has only resolved conversations in that inbox, a NEW conversation is created (not the resolved one returned)
    - When lock_to_single_conversation is true and contact has an open conversation in that inbox, the existing open conversation is returned
    - When lock_to_single_conversation is true and contact has an open conversation in Inbox A, a NEW conversation CAN be created in Inbox B (this already works, add a cross-inbox spec to prove it)
    - When lock_to_single_conversation is false, a new conversation is always created

    ContactableInboxesService:
    - WebWidget inbox appears in contactable inboxes when contact has only resolved conversations in that inbox
    - WebWidget inbox does NOT appear when contact has an open/pending/snoozed conversation in that inbox
    - WebWidget inbox does NOT appear when contact has no contact_inbox for it
  </behavior>
  <action>
    1. In `app/builders/conversation_builder.rb`, change `look_up_exising_conversation` from:
       ```ruby
       def look_up_exising_conversation
         return unless @contact_inbox.inbox.lock_to_single_conversation?
         @contact_inbox.conversations.last
       end
       ```
       To:
       ```ruby
       def look_up_exising_conversation
         return unless @contact_inbox.inbox.lock_to_single_conversation?
         @contact_inbox.conversations.where.not(status: :resolved).last
       end
       ```
       This ensures only open/pending/snoozed conversations block new conversation creation. Resolved conversations are ignored, allowing a new conversation to start.

    2. In `app/services/contacts/contactable_inboxes_service.rb`, change `website_contactable_inbox` from:
       ```ruby
       def website_contactable_inbox(inbox)
         latest_contact_inbox = inbox.contact_inboxes.where(contact: @contact).last
         return unless latest_contact_inbox
         return if latest_contact_inbox.conversations.present?
         { source_id: latest_contact_inbox.source_id, inbox: inbox }
       end
       ```
       To:
       ```ruby
       def website_contactable_inbox(inbox)
         latest_contact_inbox = inbox.contact_inboxes.where(contact: @contact).last
         return unless latest_contact_inbox
         return if latest_contact_inbox.conversations.where.not(status: :resolved).exists?
         { source_id: latest_contact_inbox.source_id, inbox: inbox }
       end
       ```
       This allows the WebWidget inbox to appear in the New Conversation dropdown when all previous conversations are resolved.

    3. Update `spec/builders/conversation_builder_spec.rb`:
       - Add test: when lock_to_single_conversation is true and existing conversations are all resolved, a new conversation is created
       - Add test: when lock_to_single_conversation is true and an open conversation exists, the existing conversation is returned
       - Add cross-inbox test: when lock_to_single_conversation is true on both inboxes, contact with open conversation in inbox A can still create in inbox B

    4. Update `spec/services/contacts/contactable_inboxes_service_spec.rb`:
       - Add test: website inbox appears when all conversations are resolved
       - Update existing test description for clarity (it tests blocking when conversation exists - should specify non-resolved)
  </action>
  <verify>
    <automated>cd D:/ivox/chatwoot && bundle exec rspec spec/builders/conversation_builder_spec.rb spec/services/contacts/contactable_inboxes_service_spec.rb --format documentation 2>&1 | tail -30</automated>
  </verify>
  <done>
    ConversationBuilder only locks to non-resolved conversations per contact_inbox. ContactableInboxesService shows WebWidget inboxes when prior conversations are resolved. All new and existing specs pass.
  </done>
</task>

<task type="auto">
  <name>Task 2: Fix incoming message services to scope lock_to_single_conversation to non-resolved conversations</name>
  <files>
    app/services/whatsapp/incoming_message_base_service.rb
    app/services/twilio/incoming_message_service.rb
    app/services/telegram/incoming_message_service.rb
    app/services/sms/incoming_message_service.rb
  </files>
  <action>
    All four incoming message services have the same pattern in their `set_conversation` method. When `lock_to_single_conversation` is true, they call `@contact_inbox.conversations.last` which returns ANY conversation including resolved ones. This causes incoming messages to be appended to resolved conversations instead of creating new ones.

    Fix each service's `set_conversation` method to filter out resolved conversations when `lock_to_single_conversation` is true:

    1. **`app/services/whatsapp/incoming_message_base_service.rb`** (line ~133):
       Change from:
       ```ruby
       @conversation = if @inbox.lock_to_single_conversation
                         @contact_inbox.conversations.last
                       else
       ```
       To:
       ```ruby
       @conversation = if @inbox.lock_to_single_conversation
                         @contact_inbox.conversations.where.not(status: :resolved).last
                       else
       ```

    2. **`app/services/twilio/incoming_message_service.rb`** (line ~100):
       Same change as above.

    3. **`app/services/telegram/incoming_message_service.rb`** (line ~81):
       Same change as above.

    4. **`app/services/sms/incoming_message_service.rb`** (line ~61):
       Same change as above.

    Note: The `else` branch already correctly filters `where.not(status: :resolved)`. The fix makes the `lock_to_single_conversation` branch consistent with this behavior -- the only difference is that the lock branch finds the last non-resolved conversation (reusing it even if snoozed/pending), while the non-lock branch creates a new conversation if none are non-resolved.

    Also fix the Instagram and Facebook message builders which have the same pattern:
    5. **`app/builders/messages/facebook/message_builder.rb`** (line ~61):
       Change `Conversation.where(conversation_params).order(created_at: :desc).first` to
       `Conversation.where(conversation_params).where.not(status: :resolved).order(created_at: :desc).first`

    6. **`app/builders/messages/instagram/base_message_builder.rb`** (line ~65):
       Change `find_conversation_scope.order(created_at: :desc).first` to
       `find_conversation_scope.where.not(status: :resolved).order(created_at: :desc).first`
  </action>
  <verify>
    <automated>cd D:/ivox/chatwoot && bundle exec rspec spec/services/whatsapp/incoming_message_service_spec.rb spec/services/twilio/incoming_message_service_spec.rb spec/services/telegram/incoming_message_service_spec.rb spec/services/sms/incoming_message_service_spec.rb spec/builders/messages/facebook/message_builder_spec.rb spec/builders/messages/instagram/messenger/message_builder_spec.rb --format documentation 2>&1 | tail -40</automated>
  </verify>
  <done>
    All six incoming message services/builders only reuse non-resolved conversations when lock_to_single_conversation is enabled. All existing specs pass (behavior for non-lock inboxes unchanged).
  </done>
</task>

</tasks>

<verification>
1. Run full spec suite for modified files:
   ```bash
   cd D:/ivox/chatwoot && bundle exec rspec \
     spec/builders/conversation_builder_spec.rb \
     spec/services/contacts/contactable_inboxes_service_spec.rb \
     spec/services/whatsapp/incoming_message_service_spec.rb \
     spec/services/twilio/incoming_message_service_spec.rb \
     spec/services/telegram/incoming_message_service_spec.rb \
     spec/services/sms/incoming_message_service_spec.rb \
     spec/builders/messages/facebook/message_builder_spec.rb \
     spec/builders/messages/instagram/messenger/message_builder_spec.rb \
     --format documentation
   ```
2. Verify no regressions in conversation creation flow.
</verification>

<success_criteria>
- ConversationBuilder only returns non-resolved conversations when lock_to_single_conversation is true
- ContactableInboxesService shows WebWidget inboxes when prior conversations are all resolved
- All incoming message services only reuse non-resolved conversations under lock
- All existing specs pass, new specs validate per-inbox non-resolved scoping
- A contact can have open conversations in multiple different inboxes simultaneously
</success_criteria>

<output>
After completion, create `.planning/quick/1-fix-conversation-lock-to-be-per-inbox-in/1-SUMMARY.md`
</output>
