# Debug script to check recent messages
account_id = 1
sender_id = 1

puts "Checking recent messages for user_id=#{sender_id}, account_id=#{account_id}"
puts "=" * 80

# Get last 10 messages from this user
recent_messages = Message.where(
  account_id: account_id,
  sender_id: sender_id
).order('created_at DESC').limit(10)

puts "\nLast 10 messages from this user (ANY type):"
puts "-" * 80

recent_messages.each do |msg|
  puts "ID: #{msg.id}"
  puts "  Content: #{msg.content&.truncate(60)}"
  puts "  Created: #{msg.created_at}"
  puts "  sender_type: #{msg.sender_type.inspect}"
  puts "  message_type: #{msg.message_type} (should be 1 for outgoing)"
  puts "  message_type enum: #{Message.message_types[msg.message_type]}" if msg.message_type
  puts ""
end

puts "\n" + "=" * 80
puts "Now checking with OUTGOING filter:"
puts "-" * 80

outgoing = Message.where(
  account_id: account_id,
  sender_id: sender_id,
  sender_type: 'User',
  message_type: Message.message_types[:outgoing]
).order('created_at DESC').limit(5)

if outgoing.any?
  outgoing.each do |msg|
    puts "ID: #{msg.id}, Content: #{msg.content&.truncate(40)}, Created: #{msg.created_at}"
  end
else
  puts "❌ NO OUTGOING MESSAGES FOUND!"
  puts "\nPossible reasons:"
  puts "1. sender_type is not 'User'"
  puts "2. message_type is not #{Message.message_types[:outgoing]}"
end
