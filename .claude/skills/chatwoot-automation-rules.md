# Skill: Chatwoot Automation Rules Debugging

## Description
Expert knowledge on Chatwoot's automation rules system, how they work, and how to troubleshoot when they don't trigger as expected.

## When to Use
- Automation rules not triggering
- Rules working in some scenarios but not others
- Rules stopped working after changes
- Need to debug specific message/conversation conditions
- Understanding automation event flow

## Key Concepts

### 1. Automation Architecture

#### Event Flow
```
Message Created
  ↓
after_create_commit callback
  ↓
execute_after_create_commit_callbacks
  ↓
dispatch_create_events
  ↓
Dispatcher sends MESSAGE_CREATED event
  ↓
AutomationRuleListener.message_created
  ↓
Check if should ignore message
  ↓
For each active rule:
  - ConditionsFilterService evaluates
  - If match → ActionService executes
```

### 2. Message Types (CRITICAL)

**Enum**: `message_type` in messages table

| Value | Type | Triggers Automation? |
|-------|------|---------------------|
| 0 | `incoming` | ✅ YES |
| 1 | `outgoing` | ✅ YES |
| 2 | `activity` | ❌ **NO** (System messages) |
| 3 | `template` | ✅ YES |

**Activity messages are ALWAYS ignored by automations!**

### 3. When Messages Are Ignored

**File**: `app/listeners/automation_rule_listener.rb:82-85`

```ruby
def ignore_message_created_event?(event)
  message = event.data[:message]
  performed_by_automation?(event) || message.activity? || message.auto_reply_email?
end
```

Messages ignored if:
1. **Type is `activity`** (message_type = 2) - System messages
2. **Is auto-reply email** - Automated email responses
3. **Performed by automation** - Prevents infinite loops

## Common Issues & Solutions

### Issue 1: External Bot Messages Don't Trigger Automations

**Symptoms**:
- Internal platform messages trigger automation ✅
- External bot/robot messages don't trigger automation ❌
- Messages appear in conversation but no automation

**Most Common Root Cause**: Messages created as `activity` type

**Diagnosis**:
```sql
-- Check message types
SELECT
  m.id,
  m.message_type,
  CASE
    WHEN m.message_type = 0 THEN 'incoming ✅'
    WHEN m.message_type = 1 THEN 'outgoing ✅'
    WHEN m.message_type = 2 THEN 'activity ❌ IGNORED'
    WHEN m.message_type = 3 THEN 'template ✅'
  END as type_label,
  m.sender_type,
  m.content
FROM messages m
WHERE m.conversation_id = :conversation_id
  AND m.content ILIKE '%keyword%'
ORDER BY m.created_at DESC;
```

**Solutions**:

1. **If bot creates messages as `activity`**: Fix the bot integration to create as `incoming` or `outgoing`

2. **If message_type condition in rule**: Remove or adjust the condition
   ```ruby
   # Don't restrict to only incoming if you want bot messages too
   conditions: [
     { attribute_key: 'content', filter_operator: 'contains', values: ['keyword'] }
     # Remove: { attribute_key: 'message_type', filter_operator: 'equal_to', values: ['0'] }
   ]
   ```

### Issue 2: Automation Worked Then Stopped

**Possible Causes**:
1. Rule was deactivated
2. Message type changed
3. Conditions changed
4. Testing with old messages (automations only work real-time)

**Diagnosis**:
```ruby
# Rails Console
rule = AutomationRule.find(rule_id)

# Check if active
rule.active?  # Must be true

# Check conditions
rule.conditions

# Test against a message
message = Message.find(message_id)
conversation = message.conversation

match = AutomationRules::ConditionsFilterService.new(
  rule,
  conversation,
  { message: message }
).perform

puts match ? "✅ Should trigger" : "❌ Won't trigger"
```

### Issue 3: Conditions Should Match But Don't

**Common Causes**:
1. **Case sensitivity**: Conditions use LOWER() for text
2. **Accents**: "revisão" ≠ "revisao"
3. **Extra spaces**: " keyword " ≠ "keyword"
4. **Multiple AND conditions**: ALL must match

**Diagnosis**:
```ruby
message = Message.find(message_id)

# Check actual content
message.content
message.processed_message_content  # Used for conditions

# Test each condition manually
content = message.processed_message_content.downcase
content.include?("keyword1")  # true?
content.include?("keyword2")  # true?
```

## Debugging Tools

### Created Rake Tasks
**File**: `lib/tasks/debug_automation.rake`

```bash
# Debug specific message
bundle exec rake chatwoot:debug_automation MESSAGE_ID=12345

# List recent messages with types
bundle exec rake chatwoot:list_recent_messages ACCOUNT_ID=1 LIMIT=30
```

**Output Shows**:
- ✅ Message details (type, sender, content)
- ✅ Why message would be ignored (if applicable)
- ✅ All active automation rules
- ✅ Condition match results
- ✅ Which specific condition failed

### SQL Queries

#### Find Messages by Content
```sql
SELECT
  m.id,
  m.message_type,
  m.sender_type,
  m.content,
  m.created_at
FROM messages m
WHERE m.account_id = :account_id
  AND m.content ILIKE '%keyword%'
ORDER BY m.created_at DESC
LIMIT 20;
```

#### Active Automation Rules
```sql
SELECT
  ar.id,
  ar.name,
  ar.event_name,
  ar.active,
  ar.conditions,
  ar.actions
FROM automation_rules ar
WHERE ar.account_id = :account_id
  AND ar.event_name = 'message_created'
  AND ar.active = true;
```

#### Message Details with Sender
```sql
SELECT
  m.id,
  m.message_type,
  m.sender_type,
  m.sender_id,
  CASE
    WHEN m.sender_type = 'User' THEN (SELECT name FROM users WHERE id = m.sender_id)
    WHEN m.sender_type = 'Contact' THEN (SELECT name FROM contacts WHERE id = m.sender_id)
    WHEN m.sender_type = 'AgentBot' THEN (SELECT name FROM agent_bots WHERE id = m.sender_id)
  END as sender_name,
  m.content
FROM messages m
WHERE m.id = :message_id;
```

### Rails Console Commands

```ruby
# Find and test a message
message = Message.find(12345)

# Check message properties
message.message_type          # incoming/outgoing/activity/template
message.activity?             # true if type = activity
message.message_type_before_type_cast  # Raw value: 0,1,2,3

# Get conversation
conversation = message.conversation

# Find automation rules
rules = AutomationRule.where(
  event_name: 'message_created',
  account_id: message.account_id,
  active: true
)

# Test each rule
rules.each do |rule|
  puts "Testing rule: #{rule.name}"

  match = AutomationRules::ConditionsFilterService.new(
    rule,
    conversation,
    { message: message }
  ).perform

  puts match ? "  ✅ Match" : "  ❌ No match"
end

# Manually trigger automation (CAREFUL - executes actions!)
Rails.configuration.dispatcher.dispatch(
  'message.created',
  Time.zone.now,
  message: message,
  performed_by: nil
)
```

## Key Files Reference

### Backend Core
- `app/models/automation_rule.rb` - Model definition
- `app/models/message.rb:300-309` - Callback execution
- `app/models/message.rb:335-344` - Event dispatching
- `app/listeners/automation_rule_listener.rb` - Event processing
- `app/services/automation_rules/conditions_filter_service.rb` - Condition evaluation
- `app/services/automation_rules/action_service.rb` - Action execution

### Configuration
- `lib/filters/filter_keys.yml` - Available condition attributes
- `lib/events/types.rb` - Event type constants

### Tests
- `spec/listeners/automation_rule_listener_spec.rb`
- `spec/services/automation_rules/conditions_filter_service_spec.rb`
- `spec/services/automation_rules/action_service_spec.rb`

### Documentation
- `docs/md/debugging_automation_rules.md` - Comprehensive guide

## Supported Events

| Event Name | When Triggered |
|-----------|----------------|
| `message_created` | New message created |
| `conversation_created` | New conversation started |
| `conversation_updated` | Conversation properties changed |
| `conversation_opened` | Conversation reopened |
| `conversation_resolved` | Conversation marked resolved |

## Supported Conditions (message_created)

### Message Attributes
- `message_type` - incoming/outgoing/template
- `content` - Message text (uses `processed_message_content`)
- `email`, `phone_number`

### Conversation Attributes
- `status` - open/resolved/pending
- `assignee_id` - Assigned agent
- `team_id` - Assigned team
- `inbox_id` - Which inbox
- `priority` - Conversation priority
- `labels` - Applied labels
- `conversation_language` - Language

### Contact Attributes
- `phone_number`, `country_code`
- `city`, `company`
- Custom attributes

## Supported Actions

- `assign_agent` - Assign to specific agent
- `assign_team` - Assign to team
- `add_label` - Add label(s)
- `remove_label` - Remove label(s)
- `send_message` - Send automated message
- `add_private_note` - Add internal note
- `send_email_to_team` - Email notification
- `mute_conversation` - Mute conversation
- `snooze_conversation` - Snooze for later
- `resolve_conversation` - Mark as resolved
- `change_priority` - Update priority
- `send_webhook_event` - Trigger webhook

## Filter Operators

| Operator | Works On | Example |
|----------|----------|---------|
| `equal_to` | All types | status = 'open' |
| `not_equal_to` | All types | status ≠ 'resolved' |
| `contains` | Text | content contains 'help' |
| `does_not_contain` | Text | content not contains 'spam' |
| `is_present` | All types | assignee is present |
| `is_not_present` | All types | assignee is not present |
| `starts_with` | Text | content starts with 'Hello' |
| `is_greater_than` | Numeric/Date | priority > 1 |
| `is_less_than` | Numeric/Date | age < 30 |

## Best Practices

1. **Test with new messages**: Automations only work real-time, not retroactively
2. **Check message_type**: Most common issue is `activity` type messages
3. **Use rake tasks**: Faster than manual Rails console debugging
4. **Verify sender_type**: Know if message is from User/Contact/AgentBot
5. **Test conditions separately**: Verify each condition individually
6. **Watch for case sensitivity**: All text comparisons are lowercased
7. **Consider timing**: Messages must complete creation before automation runs

## Troubleshooting Checklist

- [ ] Check if rule is active: `rule.active?`
- [ ] Verify message_type is NOT `activity` (2)
- [ ] Confirm message was created AFTER rule was activated
- [ ] Test conditions manually with actual message content
- [ ] Check for message_type condition restricting incoming/outgoing
- [ ] Verify sender_type if rule filters by sender
- [ ] Look for ActionCable/automation errors in logs
- [ ] Test with debug rake task
- [ ] Confirm account_id matches between rule and message

## Common Patterns

### Pattern 1: Keyword-Based Assignment
```ruby
# When customer mentions "billing", assign to billing team
conditions: [
  { attribute_key: 'message_type', filter_operator: 'equal_to', values: [0] },
  { attribute_key: 'content', filter_operator: 'contains', values: ['billing'] }
]
actions: [
  { action_name: 'assign_team', action_params: [billing_team_id] }
]
```

### Pattern 2: Auto-Label High Priority
```ruby
# VIP customers get priority label
conditions: [
  { attribute_key: 'message_type', filter_operator: 'equal_to', values: [0] },
  { attribute_key: 'labels', filter_operator: 'contains', values: ['vip'] }
]
actions: [
  { action_name: 'add_label', action_params: ['high-priority'] },
  { action_name: 'change_priority', action_params: ['urgent'] }
]
```

### Pattern 3: Bot-Triggered Follow-up
```ruby
# When bot sends specific message, assign to human
conditions: [
  { attribute_key: 'content', filter_operator: 'contains', values: ['transfer', 'agent'] }
  # NO message_type restriction! Works for both incoming and outgoing
]
actions: [
  { action_name: 'assign_agent', action_params: [agent_id] },
  { action_name: 'add_private_note', action_params: ['Bot requested human agent'] }
]
```

## Integration with External Systems

### WhatsApp Bot Messages
- Bot sends via WhatsApp API → Webhook → `Whatsapp::IncomingMessageService`
- Messages created with `message_type: :incoming` (line 153)
- Sender is `Contact` (customer)
- ✅ Should trigger automations normally

### If Bot Messages Don't Trigger
1. Check if bot creates messages via API instead of webhook
2. Verify message_type is not `activity`
3. Check if rule has message_type condition
4. Use debug rake task to identify exact issue

## Logs and Monitoring

```ruby
# Enable automation logging (development/staging)
# In app/listeners/automation_rule_listener.rb

def message_created(event)
  message = event.data[:message]

  Rails.logger.info "=== AUTOMATION: Message #{message.id} ==="
  Rails.logger.info "Type: #{message.message_type}"
  Rails.logger.info "Ignored?: #{ignore_message_created_event?(event)}"

  # ... existing code
end
```

View logs:
```bash
tail -f log/development.log | grep "AUTOMATION"
tail -f log/production.log | grep -i "automation"
```
