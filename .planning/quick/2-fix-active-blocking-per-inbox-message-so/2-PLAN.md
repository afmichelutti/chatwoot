---
phase: quick-2
plan: 1
type: execute
wave: 1
depends_on: []
files_modified:
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
autonomous: true
requirements: [QUICK-2]
must_haves:
  truths:
    - "When lock_to_single_conversation is enabled, incoming messages only reuse a conversation that has at least one outgoing (operator) message; otherwise a new conversation is created"
    - "Contacts list defaults to alphabetical sort (by name) and the last_activity_at sort option is removed from the UI"
    - "Operator can select multiple conversations in bulk and mark them as unread"
  artifacts:
    - path: "app/services/whatsapp/incoming_message_base_service.rb"
      provides: "Active-conversation-aware lock logic for WhatsApp"
      contains: "messages.where(message_type: :outgoing)"
    - path: "app/javascript/dashboard/components-next/Contacts/ContactsHeader/components/ContactSortMenu.vue"
      provides: "Contact sort menu without last_activity_at option"
    - path: "app/javascript/dashboard/components/widgets/conversation/conversationBulkActions/Index.vue"
      provides: "Bulk mark-as-unread button in conversation bulk actions bar"
    - path: "app/jobs/bulk_actions_job.rb"
      provides: "Backend bulk mark_as_unread action"
  key_links:
    - from: "all incoming message services"
      to: "conversation.messages.outgoing"
      via: "query for outgoing messages to determine active lock"
    - from: "ConversationBulkActions/Index.vue"
      to: "useBulkActions.js"
      via: "emit -> onMarkAsUnread -> bulkActions/process"
    - from: "BulkActionsJob"
      to: "conversation.update_columns"
      via: "bulk_mark_as_unread iterating over records"
---

<objective>
Implement three related conversation/contact improvements:
1. Redefine "active" for lock_to_single_conversation: only lock to conversations where an operator has replied (has outgoing messages), not just any conversation
2. Default contacts sort to alphabetical (name) and remove the last_activity_at sort option
3. Add batch "mark as unread" option in conversation bulk actions

Purpose: These are operator-requested workflow improvements to make conversation routing smarter, contact lists more usable, and bulk operations more complete.
Output: Modified backend services, frontend components, and i18n strings.
</objective>

<execution_context>
@C:/Users/afmic/.claude/get-shit-done/workflows/execute-plan.md
@C:/Users/afmic/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/STATE.md
@.planning/quick/1-fix-conversation-lock-to-be-per-inbox-in/1-SUMMARY.md
@AGENTS.md
</context>

<interfaces>
<!-- Key types and patterns the executor needs -->

From app/services/whatsapp/incoming_message_base_service.rb (set_conversation pattern):
```ruby
def set_conversation
  @conversation = if @inbox.lock_to_single_conversation
                    @contact_inbox.conversations.last
                  else
                    @contact_inbox.conversations.where.not(status: :resolved).last
                  end
  return if @conversation
  @conversation = ::Conversation.create!(conversation_params)
end
```

From app/builders/messages/facebook/message_builder.rb (set_conversation pattern):
```ruby
def set_conversation_based_on_inbox_config
  if @inbox.lock_to_single_conversation
    Conversation.where(conversation_params).order(created_at: :desc).first || build_conversation
  else
    find_or_build_for_multiple_conversations
  end
end
```

From app/builders/conversation_builder.rb:
```ruby
def look_up_exising_conversation
  return unless @contact_inbox.inbox.lock_to_single_conversation?
  @contact_inbox.conversations.where.not(status: :resolved).last
end
```

From app/jobs/bulk_actions_job.rb:
```ruby
def bulk_update
  bulk_remove_labels
  bulk_conversation_update
end
```

From app/controllers/api/v1/accounts/conversations_controller.rb (unread action):
```ruby
def unread
  last_incoming_message = @conversation.messages.incoming.last
  last_seen_at = last_incoming_message.created_at - 1.second if last_incoming_message.present?
  update_last_seen_on_conversation(last_seen_at, true)
end
```

From message model enum:
```ruby
enum message_type: { incoming: 0, outgoing: 1, activity: 2, template: 3 }
```

From ContactSortMenu.vue sortMenus array:
```javascript
const sortMenus = [
  { label: '...NAME', value: 'name' },
  { label: '...EMAIL', value: 'email' },
  { label: '...COMPANY', value: 'company_name' },
  { label: '...COUNTRY', value: 'country' },
  { label: '...CITY', value: 'city' },
  { label: '...LAST_ACTIVITY', value: 'last_activity_at' },
  { label: '...CREATED_AT', value: 'created_at' },
];
```

From ConversationBulkActions emits:
```javascript
emits: ['selectAllConversations', 'assignAgent', 'updateConversations', 'assignLabels', 'assignTeam', 'resolveConversations']
```
</interfaces>

<tasks>

<task type="auto">
  <name>Task 1: Redefine lock_to_single_conversation to require operator activity</name>
  <files>
    app/services/whatsapp/incoming_message_base_service.rb
    app/services/twilio/incoming_message_service.rb
    app/services/telegram/incoming_message_service.rb
    app/services/sms/incoming_message_service.rb
    app/builders/messages/facebook/message_builder.rb
    app/builders/messages/instagram/base_message_builder.rb
    app/builders/conversation_builder.rb
  </files>
  <action>
  Change the meaning of "active conversation" when `lock_to_single_conversation` is enabled. Currently, when the lock is on, the system reuses the last conversation (any status for incoming message services, or non-resolved for ConversationBuilder). The new behavior: only reuse a conversation if it has at least one outgoing message (meaning an operator has replied in it).

  For each incoming message service (WhatsApp, Twilio, Telegram, SMS), modify the `set_conversation` method:

  **WhatsApp (`incoming_message_base_service.rb`):**
  Change the lock branch from `@contact_inbox.conversations.last` to:
  ```ruby
  @contact_inbox.conversations
    .joins(:messages)
    .where(messages: { message_type: :outgoing })
    .order(created_at: :desc)
    .first
  ```
  Keep the non-lock branch as-is (`.where.not(status: :resolved).last`).
  Update the comment to: "if lock is enabled, reuse only conversations where an operator has replied (has outgoing messages)"

  **Twilio (`incoming_message_service.rb`):** Same pattern as WhatsApp.

  **Telegram (`incoming_message_service.rb`):** Same pattern as WhatsApp.

  **SMS (`incoming_message_service.rb`):** Same pattern as WhatsApp.

  **Facebook (`message_builder.rb`):**
  Change `set_conversation_based_on_inbox_config` lock branch from:
  `Conversation.where(conversation_params).order(created_at: :desc).first`
  to:
  `Conversation.where(conversation_params).joins(:messages).where(messages: { message_type: :outgoing }).order(created_at: :desc).first`
  Keep the `|| build_conversation` fallback.

  **Instagram (`base_message_builder.rb`):**
  Change `find_conversation_scope` is used only in the lock branch, so update `set_conversation_based_on_inbox_config`:
  Change the lock branch from `find_conversation_scope.order(created_at: :desc).first` to:
  `find_conversation_scope.joins(:messages).where(messages: { message_type: :outgoing }).order(created_at: :desc).first`

  **ConversationBuilder (`conversation_builder.rb`):**
  Change `look_up_exising_conversation` from:
  `@contact_inbox.conversations.where.not(status: :resolved).last`
  to:
  `@contact_inbox.conversations.where.not(status: :resolved).joins(:messages).where(messages: { message_type: :outgoing }).last`
  This ensures the operator-created-conversation flow also respects "active = operator replied".
  </action>
  <verify>
    <automated>cd D:/ivox/chatwoot && grep -n "message_type.*outgoing\|outgoing.*message_type" app/services/whatsapp/incoming_message_base_service.rb app/services/twilio/incoming_message_service.rb app/services/telegram/incoming_message_service.rb app/services/sms/incoming_message_service.rb app/builders/messages/facebook/message_builder.rb app/builders/messages/instagram/base_message_builder.rb app/builders/conversation_builder.rb | wc -l</automated>
  </verify>
  <done>All 7 files check for outgoing messages when lock_to_single_conversation is enabled. A conversation without operator replies will NOT be reused -- a new conversation is created instead.</done>
</task>

<task type="auto">
  <name>Task 2: Default contacts sort to name, remove last_activity_at option</name>
  <files>
    app/javascript/dashboard/components-next/Contacts/ContactsHeader/components/ContactSortMenu.vue
    app/javascript/dashboard/routes/dashboard/contacts/pages/ContactsIndex.vue
  </files>
  <action>
  **ContactSortMenu.vue:**
  Remove the `last_activity_at` entry from the `sortMenus` array (the one with value `'last_activity_at'`). Keep all other sort options (name, email, company_name, country, city, created_at).

  **ContactsIndex.vue:**
  Change the `DEFAULT_SORT_FIELD` constant from `'last_activity_at'` to `'name'`:
  ```javascript
  const DEFAULT_SORT_FIELD = 'name';
  ```
  This ensures when no sort preference is stored in uiSettings, contacts default to alphabetical by name.
  </action>
  <verify>
    <automated>cd D:/ivox/chatwoot && grep -c "last_activity_at" app/javascript/dashboard/components-next/Contacts/ContactsHeader/components/ContactSortMenu.vue && grep "DEFAULT_SORT_FIELD" app/javascript/dashboard/routes/dashboard/contacts/pages/ContactsIndex.vue</automated>
  </verify>
  <done>ContactSortMenu.vue has 0 occurrences of last_activity_at. DEFAULT_SORT_FIELD is 'name'. Contacts list sorts alphabetically by default.</done>
</task>

<task type="auto">
  <name>Task 3: Add batch mark-as-unread for conversations</name>
  <files>
    app/jobs/bulk_actions_job.rb
    app/javascript/dashboard/composables/chatlist/useBulkActions.js
    app/javascript/dashboard/components/widgets/conversation/conversationBulkActions/Index.vue
    app/javascript/dashboard/components/ChatList.vue
    app/javascript/dashboard/i18n/locale/en/bulkActions.json
  </files>
  <action>
  **Backend -- `bulk_actions_job.rb`:**
  Add a `bulk_mark_as_unread` method and call it from `bulk_update`:

  ```ruby
  def bulk_update
    bulk_remove_labels
    bulk_mark_as_unread
    bulk_conversation_update
  end

  def bulk_mark_as_unread
    return unless @params[:action_name] == 'mark_as_unread'

    records.each do |conversation|
      last_incoming_message = conversation.messages.incoming.last
      next unless last_incoming_message

      last_seen_at = last_incoming_message.created_at - 1.second
      conversation.update_columns(
        agent_last_seen_at: last_seen_at,
        assignee_last_seen_at: last_seen_at
      )
    end
  end
  ```

  Also update `bulk_actions_controller.rb` to permit `action_name` in the conversation_params method. Check if `action_name` is already permitted via `append_common_bulk_attributes` -- it IS, via `common = params.permit(:type, :action_name, ...)`. So no controller change needed.

  **Frontend -- `useBulkActions.js`:**
  Add a new `onMarkAsUnread` function:

  ```javascript
  async function onMarkAsUnread() {
    try {
      await store.dispatch('bulkActions/process', {
        type: 'Conversation',
        ids: selectedConversations.value,
        action_name: 'mark_as_unread',
      });
      store.dispatch('bulkActions/clearSelectedConversationIds');
      useAlert(t('BULK_ACTION.MARK_AS_UNREAD.SUCCESS'));
    } catch (err) {
      useAlert(t('BULK_ACTION.MARK_AS_UNREAD.FAILED'));
    }
  }
  ```

  Add `onMarkAsUnread` to the returned object.

  **Frontend -- `ConversationBulkActions/Index.vue`:**
  Add a "Mark as unread" button next to the existing action buttons. Add it as the first button in the `bulk-action__actions` div:

  ```html
  <NextButton
    v-tooltip="$t('BULK_ACTION.MARK_AS_UNREAD.TOOLTIP')"
    icon="i-lucide-mail"
    slate
    xs
    faded
    @click="markAsUnread"
  />
  ```

  Add `markAsUnread` to emits array. Add a `markAsUnread` method:
  ```javascript
  markAsUnread() {
    this.$emit('markAsUnread');
  },
  ```

  **Frontend -- `ChatList.vue`:**
  Wire the new event. In the `useBulkActions()` destructure, add `onMarkAsUnread`.
  On the `<ConversationBulkActions>` component, add `@mark-as-unread="onMarkAsUnread"`.

  **i18n -- `bulkActions.json`:**
  Add under `BULK_ACTION`:
  ```json
  "MARK_AS_UNREAD": {
    "TOOLTIP": "Mark as unread",
    "SUCCESS": "Conversations marked as unread successfully.",
    "FAILED": "Failed to mark conversations as unread. Please try again."
  }
  ```
  </action>
  <verify>
    <automated>cd D:/ivox/chatwoot && grep -c "mark_as_unread" app/jobs/bulk_actions_job.rb && grep -c "onMarkAsUnread" app/javascript/dashboard/composables/chatlist/useBulkActions.js && grep -c "MARK_AS_UNREAD" app/javascript/dashboard/i18n/locale/en/bulkActions.json</automated>
  </verify>
  <done>BulkActionsJob handles mark_as_unread action_name. useBulkActions exports onMarkAsUnread. ConversationBulkActions has the mark-as-unread button. i18n keys exist. Operator can select conversations in bulk and mark them as unread.</done>
</task>

</tasks>

<verification>
1. All incoming message services (WhatsApp, Twilio, Telegram, SMS, Facebook, Instagram) + ConversationBuilder check for outgoing messages when lock is enabled
2. ContactSortMenu no longer offers last_activity_at, default sort is name
3. Bulk mark-as-unread works end-to-end: button visible, dispatches API call, backend processes it
</verification>

<success_criteria>
- lock_to_single_conversation only reuses conversations with operator replies (outgoing messages)
- Contacts list defaults to alphabetical sort; last_activity_at option removed from sort menu
- Batch mark-as-unread button appears in conversation bulk action bar and functions correctly
</success_criteria>

<output>
After completion, create `.planning/quick/2-fix-active-blocking-per-inbox-message-so/2-SUMMARY.md`
</output>
