# Test JSON serialization for Cloves' conversations
puts "==== Testing JSON Serialization ===="

user = User.find_by(email: 'cloves@caperbrasil.com.br')
account = Account.find(1)

puts "User: #{user.name} (ID: #{user.id})"
puts "Account: #{account.name}"

# Get conversations
conversations = account.conversations
  .where(status: :open, assignee_id: user.id)
  .includes(
    :taggings, :inbox,
    { assignee: { avatar_attachment: [:blob] } },
    { contact: { avatar_attachment: [:blob] } },
    :team, :contact_inbox
  )
  .order(last_activity_at: :desc)
  .page(1)
  .per(25)

puts "\nFound #{conversations.count} conversations"

# Test each conversation serialization
conversations.each_with_index do |conv, index|
  begin
    puts "\n[#{index + 1}/#{conversations.count}] Testing conversation ##{conv.display_id}..."

    # Test assignee.account (linha 10 da view)
    if conv.assignee
      if conv.assignee.account.nil?
        puts "  ⚠️  WARNING: Assignee #{conv.assignee.email} has NO account!"
      else
        puts "  ✅ Assignee: #{conv.assignee.email} (account OK)"
      end
    end

    # Test contact
    if conv.contact.nil?
      puts "  ⚠️  WARNING: No contact!"
    else
      puts "  ✅ Contact: #{conv.contact.name}"
    end

    # Test inbox
    if conv.inbox.nil?
      puts "  ⚠️  WARNING: No inbox!"
    else
      puts "  ✅ Inbox: #{conv.inbox.name}"
    end

    # Test contact_inbox
    if conv.contact_inbox.nil?
      puts "  ⚠️  WARNING: No contact_inbox!"
    else
      puts "  ✅ Contact Inbox: OK"
    end

    # Test last message
    last_msg = conv.messages.where(account_id: conv.account_id).last
    if last_msg.nil?
      puts "  ⚠️  WARNING: No messages!"
    else
      puts "  ✅ Last message: #{last_msg.id}"

      # Test push_event_data (pode causar erro)
      begin
        data = last_msg.push_event_data
        puts "  ✅ push_event_data: OK"
      rescue => e
        puts "  ❌ ERROR in push_event_data: #{e.message}"
        puts "     #{e.backtrace.first}"
        raise
      end
    end

    # Test unread_incoming_messages.count (linha 50)
    begin
      unread_count = conv.unread_incoming_messages.count
      puts "  ✅ Unread count: #{unread_count}"
    rescue => e
      puts "  ❌ ERROR in unread_incoming_messages: #{e.message}"
      raise
    end

    # Test last_non_activity_message (linha 51)
    begin
      last_non_activity = conv.messages.where(account_id: conv.account_id).non_activity_messages.first
      if last_non_activity
        data = last_non_activity.push_event_data
        puts "  ✅ last_non_activity_message: OK"
      else
        puts "  ⚠️  No non-activity messages"
      end
    rescue => e
      puts "  ❌ ERROR in last_non_activity_message: #{e.message}"
      puts "     #{e.backtrace.first}"
      raise
    end

  rescue => e
    puts "\n==== ERROR FOUND in conversation ##{conv.display_id} ===="
    puts "Error: #{e.class.name}: #{e.message}"
    puts "\nBacktrace:"
    puts e.backtrace.first(15).join("\n")
    puts "\nConversation details:"
    puts "  ID: #{conv.id}"
    puts "  Display ID: #{conv.display_id}"
    puts "  Status: #{conv.status}"
    puts "  Assignee ID: #{conv.assignee_id}"
    puts "  Contact ID: #{conv.contact_id}"
    puts "  Inbox ID: #{conv.inbox_id}"
    puts "  Created at: #{conv.created_at}"
    exit 1
  end
end

puts "\n==== All conversations serialized successfully! ===="
puts "The error is NOT in serialization."
puts "Check controller authorization or middleware."
