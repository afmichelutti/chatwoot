# Find corrupted conversations in "unassigned" list

puts "==== Finding Corrupted Unassigned Conversations ===="

account = Account.find(1)

# Get unassigned conversations (same filter as the API endpoint)
conversations = account.conversations
  .where(status: :open, assignee_id: nil)
  .includes(
    :taggings, :inbox,
    { contact: { avatar_attachment: [:blob] } },
    :team, :contact_inbox
  )
  .order(last_activity_at: :desc)
  .limit(100)

puts "Found #{conversations.count} open unassigned conversations"
puts "\n==== Testing each conversation for serialization errors ===="

corrupted = []

conversations.each_with_index do |conv, index|
  begin
    print "[#{index + 1}/#{conversations.count}] Testing conversation ##{conv.display_id}... "

    # Test contact_inbox
    if conv.contact_inbox.nil?
      puts "❌ CORRUPTED: No contact_inbox!"
      corrupted << { conv: conv, reason: 'contact_inbox is nil' }
      next
    end

    # Test contact
    if conv.contact.nil?
      puts "❌ CORRUPTED: No contact!"
      corrupted << { conv: conv, reason: 'contact is nil' }
      next
    end

    # Test last message serialization
    last_msg = conv.messages.where(account_id: conv.account_id).last
    if last_msg
      begin
        data = last_msg.push_event_data
        puts "✅ OK"
      rescue => e
        puts "❌ ERROR in push_event_data: #{e.message}"
        corrupted << { conv: conv, reason: "push_event_data error: #{e.message}" }
      end
    else
      puts "⚠️  No messages"
    end

  rescue => e
    puts "❌ EXCEPTION: #{e.message}"
    corrupted << { conv: conv, reason: "Exception: #{e.message}" }
  end
end

puts "\n==== Summary ===="
puts "Total conversations tested: #{conversations.count}"
puts "Corrupted conversations found: #{corrupted.length}"

if corrupted.any?
  puts "\n==== Corrupted Conversations ===="
  corrupted.each do |item|
    conv = item[:conv]
    reason = item[:reason]

    puts "\nConversation ##{conv.display_id} (ID: #{conv.id})"
    puts "  Status: #{conv.status}"
    puts "  Assignee: #{conv.assignee_id || 'Unassigned'}"
    puts "  Contact ID: #{conv.contact_id}"
    puts "  Contact Inbox ID: #{conv.contact_inbox_id || 'NIL'}"
    puts "  Created: #{conv.created_at}"
    puts "  Reason: #{reason}"
  end

  puts "\n==== Suggested Fix ===="
  puts "Run this command to resolve all corrupted conversations:"
  puts ""
  puts "Conversation.where(id: [#{corrupted.map { |c| c[:conv].id }.join(', ')}]).update_all(status: 1)"
  puts ""
  puts "Or mark them as resolved one by one in Rails console:"
  corrupted.each do |item|
    puts "Conversation.find(#{item[:conv].id}).update!(status: :resolved)"
  end
else
  puts "\n✅ No corrupted conversations found!"
  puts "The error might be somewhere else. Check production logs for stack trace."
end

puts "\n==== Testing complete ===="
