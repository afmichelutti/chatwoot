# Fix corrupted conversation #164207 that is causing 500 error
# This conversation has no contact_inbox, causing serialization to fail

puts "==== Fixing Corrupted Conversation #164207 ===="

# Find the problematic conversation
conv = Conversation.find_by(display_id: 164207, account_id: 1)

if conv.nil?
  puts "ERROR: Conversation #164207 not found!"
  exit 1
end

puts "Found conversation:"
puts "  Display ID: #{conv.display_id}"
puts "  Internal ID: #{conv.id}"
puts "  Status: #{conv.status}"
puts "  Contact ID: #{conv.contact_id}"
puts "  Contact Inbox ID: #{conv.contact_inbox_id} (#{conv.contact_inbox_id.nil? ? 'NIL - PROBLEMA!' : 'OK'})"
puts "  Assignee: #{conv.assignee&.email}"
puts "  Created at: #{conv.created_at}"
puts "  Messages count: #{conv.messages.count}"

# Check if contact_inbox is really nil
if conv.contact_inbox.present?
  puts "\n✅ Contact inbox exists! No fix needed."
  exit 0
end

puts "\n⚠️  Contact inbox is NIL - this is causing the 500 error!"
puts "\n==== Solution: Mark conversation as RESOLVED ===="
puts "This will remove it from the 'open' list and stop the error."

# Resolve the conversation
begin
  conv.status = :resolved
  conv.save!(validate: false) # Skip validations to avoid issues

  puts "\n✅ SUCCESS! Conversation #164207 marked as RESOLVED"
  puts "   The 500 error should be fixed now for user Cloves."
  puts "\n📝 Note: You can reopen this conversation later if needed."
  puts "   But you should fix the contact_inbox issue first."

rescue => e
  puts "\n❌ ERROR: Failed to resolve conversation"
  puts "   #{e.message}"
  puts "\n   Trying alternative method..."

  # Alternative: Update directly via SQL
  begin
    ActiveRecord::Base.connection.execute(
      "UPDATE conversations SET status = 1 WHERE id = #{conv.id}"
    )
    puts "✅ SUCCESS via SQL! Conversation marked as RESOLVED"
  rescue => e2
    puts "❌ FAILED: #{e2.message}"
  end
end

puts "\n==== Verification ===="
conv.reload
puts "Final status: #{conv.status} (#{conv.status == 'resolved' ? '✅ RESOLVED' : '❌ Still open'})"

# Show remaining open conversations for Cloves
user = User.find_by(email: 'cloves@caperbrasil.com.br')
open_count = Conversation.where(status: :open, assignee_id: user.id).count
puts "\nRemaining open conversations for Cloves: #{open_count}"
