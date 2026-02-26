# Test if conversation_participating_manage permission filters contact conversations correctly

puts "==== Testing Contact Conversation Permission Filter ===="

# Find a user with conversation_participating_manage permission
user = User.find_by(email: 'cintiajoaoiza@gmail.com') # First user from the list with "Cobrança" role
account = Account.find(1)

puts "User: #{user.name} (#{user.email})"
puts "Account: #{account.name}"

# Check permissions
account_user = AccountUser.find_by(account_id: account.id, user_id: user.id)
puts "\nUser Role: #{account_user.role}"
puts "Custom Role: #{account_user.custom_role&.name}"
puts "Permissions: #{account_user.permissions.inspect}"

# Find a contact with multiple conversations
contact = Contact.joins(:conversations)
  .where(conversations: { account_id: account.id })
  .group('contacts.id')
  .having('COUNT(conversations.id) > 1')
  .first

if contact.nil?
  puts "\nNo contact found with multiple conversations!"
  exit 1
end

puts "\n==== Testing with Contact: #{contact.name} ===="
puts "Contact ID: #{contact.id}"

# Get all conversations for this contact (without filter)
all_conversations = account.conversations.where(contact_id: contact.id)
puts "\nTotal conversations for this contact: #{all_conversations.count}"

# Show conversation details
all_conversations.each do |conv|
  assignee_name = conv.assignee ? conv.assignee.name : "Unassigned"
  puts "  - Conversation ##{conv.display_id} | Status: #{conv.status} | Assigned to: #{assignee_name} (ID: #{conv.assignee_id})"
end

# Now apply the permission filter (simulating what the controller does)
puts "\n==== Applying PermissionFilterService ===="

filtered_conversations = Conversations::PermissionFilterService.new(
  all_conversations,
  user,
  account
).perform

puts "Filtered conversations count: #{filtered_conversations.count}"

# Show filtered results
filtered_conversations.each do |conv|
  assignee_name = conv.assignee ? conv.assignee.name : "Unassigned"
  puts "  - Conversation ##{conv.display_id} | Status: #{conv.status} | Assigned to: #{assignee_name} (ID: #{conv.assignee_id})"
end

# Expected behavior
expected_count = all_conversations.where(assignee_id: user.id).count
puts "\n==== Analysis ===="
puts "Expected conversations (assigned to user): #{expected_count}"
puts "Actual filtered conversations: #{filtered_conversations.count}"

if filtered_conversations.count == expected_count
  puts "\n✅ PASS: Filter is working correctly!"
  puts "   User can only see conversations assigned to them."
else
  puts "\n❌ FAIL: Filter is NOT working correctly!"
  puts "   User is seeing #{filtered_conversations.count - expected_count} extra conversations."

  # Show which conversations shouldn't be visible
  extra_convs = filtered_conversations.where.not(assignee_id: user.id)
  if extra_convs.any?
    puts "\n   Conversations user SHOULDN'T see:"
    extra_convs.each do |conv|
      assignee_name = conv.assignee ? conv.assignee.name : "Unassigned"
      puts "     - Conversation ##{conv.display_id} | Assigned to: #{assignee_name}"
    end
  end
end

puts "\n==== Testing complete ===="
