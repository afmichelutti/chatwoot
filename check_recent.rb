# Check most recent messages in the system
puts "Most recent messages in the system (last 10):"
puts "=" * 80

recent = Message.where(account_id: 1).order('created_at DESC').limit(10)

recent.each do |msg|
  puts "\nID: #{msg.id}"
  puts "  Content: #{msg.content&.truncate(60)}"
  puts "  Created: #{msg.created_at}"
  puts "  Conversation ID: #{msg.conversation_id}"
  puts "  Inbox ID: #{msg.inbox_id}"
  puts "  sender_id: #{msg.sender_id}"
  puts "  sender_type: #{msg.sender_type}"
  puts "  message_type: #{msg.message_type} (#{Message.message_types.key(msg.message_type)})"
end

puts "\n" + "=" * 80
puts "\nNow checking the specific message you mentioned (ID 5119614):"
puts "-" * 80

specific = Message.find_by(id: 5119614)
if specific
  puts "✅ Found message 5119614:"
  puts "  Content: #{specific.content}"
  puts "  Created: #{specific.created_at}"
  puts "  sender_id: #{specific.sender_id}"
  puts "  sender_type: #{specific.sender_type}"
  puts "  message_type: #{specific.message_type} (#{Message.message_types.key(specific.message_type)})"
  puts "  account_id: #{specific.account_id}"

  if specific.sender_id != 1
    puts "\n❌ PROBLEM: sender_id is #{specific.sender_id}, not 1!"
  end

  if specific.sender_type != 'User'
    puts "\n❌ PROBLEM: sender_type is '#{specific.sender_type}', not 'User'!"
  end

  if specific.message_type != Message.message_types[:outgoing]
    puts "\n❌ PROBLEM: message_type is #{specific.message_type}, not #{Message.message_types[:outgoing]} (outgoing)!"
  end
else
  puts "❌ Message 5119614 not found!"
end
