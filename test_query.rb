# Test script to verify the query works
account_id = 1
sender_id = 1

puts "Testing message query..."
puts "=" * 50

# Old buggy query
old_result = Message.where(
  account_id: account_id,
  sender_id: sender_id,
  sender_type: 'User',
  message_type: Message.message_types[:outgoing]
).order(created_at: :desc).first

puts "OLD QUERY (buggy):"
puts "  ID: #{old_result&.id}"
puts "  Content: #{old_result&.content&.truncate(50)}"
puts "  Created: #{old_result&.created_at}"
puts ""

# New fixed query
new_result = Message.where(
  account_id: account_id,
  sender_id: sender_id,
  sender_type: 'User',
  message_type: Message.message_types[:outgoing]
).order('created_at DESC').limit(1).first

puts "NEW QUERY (fixed):"
puts "  ID: #{new_result&.id}"
puts "  Content: #{new_result&.content&.truncate(50)}"
puts "  Created: #{new_result&.created_at}"
puts ""

if old_result&.id != new_result&.id
  puts "❌ QUERIES RETURN DIFFERENT RESULTS!"
else
  puts "✅ Queries return the same result"
end
