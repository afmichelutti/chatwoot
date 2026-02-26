# Test if the permission fix works correctly

puts "==== Testing Permission Fix for conversation_participating_manage ===="

# Setup
user = User.find_by(email: 'cintiajoaoiza@gmail.com')
account = Account.find(1)
Current.account = account
Current.user = user

puts "User: #{user.name} (#{user.email})"
puts "Permissions: #{user.account_users.find_by(account_id: account.id).permissions.inspect}"

# Find a conversation NOT assigned to this user
other_conversation = account.conversations
  .where.not(assignee_id: user.id)
  .where.not(assignee_id: nil)
  .first

# Find a conversation assigned to this user
my_conversation = account.conversations
  .where(assignee_id: user.id)
  .first

puts "\n==== Test 1: Accessing MY conversation ===="
puts "Conversation ##{my_conversation.display_id} (assigned to me)"

# Simulate the check_conversation_permission! method
filtered = Conversations::PermissionFilterService.new(
  Conversation.where(id: my_conversation.id),
  Current.user,
  Current.account
).perform

if filtered.exists?
  puts "✅ PASS: Can access my own conversation"
else
  puts "❌ FAIL: Cannot access my own conversation (this is wrong!)"
end

puts "\n==== Test 2: Accessing OTHER user's conversation ===="
puts "Conversation ##{other_conversation.display_id} (assigned to #{other_conversation.assignee.name})"

# Simulate the check_conversation_permission! method
filtered = Conversations::PermissionFilterService.new(
  Conversation.where(id: other_conversation.id),
  Current.user,
  Current.account
).perform

if filtered.exists?
  puts "❌ FAIL: Can access other user's conversation (BUG!)"
else
  puts "✅ PASS: Cannot access other user's conversation (correctly blocked)"
end

puts "\n==== Test 3: Administrator should see all conversations ===="

admin_user = User.joins(:account_users)
  .where(account_users: { account_id: account.id, role: 'administrator' })
  .first

if admin_user
  puts "Admin: #{admin_user.name} (#{admin_user.email})"

  filtered = Conversations::PermissionFilterService.new(
    Conversation.where(id: other_conversation.id),
    admin_user,
    account
  ).perform

  if filtered.exists?
    puts "✅ PASS: Admin can see all conversations"
  else
    puts "❌ FAIL: Admin cannot see conversation (this is wrong!)"
  end
else
  puts "⚠️  No administrator found in this account"
end

puts "\n==== Summary ===="
puts "The fix in app/controllers/api/v1/accounts/conversations_controller.rb"
puts "adds check_conversation_permission! method that:"
puts "  1. Uses PermissionFilterService to check conversation access"
puts "  2. Returns 403 Forbidden if user doesn't have permission"
puts "  3. Respects conversation_participating_manage permission"
puts ""
puts "This prevents agents from accessing conversations not assigned to them!"

puts "\n==== Testing complete ===="
