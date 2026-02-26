# Test if agent with conversation_participating_manage can open conversations not assigned to them

puts "==== Testing Opening Unassigned Conversation ===="

# User with conversation_participating_manage
user = User.find_by(email: 'cintiajoaoiza@gmail.com')
account = Account.find(1)

puts "User: #{user.name} (#{user.email})"
puts "User ID: #{user.id}"

account_user = AccountUser.find_by(account_id: account.id, user_id: user.id)
puts "Permissions: #{account_user.permissions.inspect}"

# Find a conversation NOT assigned to this user
conversation = account.conversations
  .where.not(assignee_id: user.id)
  .where.not(assignee_id: nil)  # Must be assigned to someone else
  .first

if conversation.nil?
  puts "\nNo conversation found assigned to another user!"
  exit 1
end

puts "\n==== Conversation Details ===="
puts "Conversation ##{conversation.display_id} (ID: #{conversation.id})"
puts "Status: #{conversation.status}"
puts "Assigned to: #{conversation.assignee&.name} (ID: #{conversation.assignee_id})"
puts "Contact: #{conversation.contact.name}"
puts "User ID: #{user.id}"

puts "\n==== Testing Access ===="

# Simulate what happens when user tries to access this conversation
# This is what the controller does in the 'show' action

# Step 1: Can find the conversation?
begin
  found_conv = account.conversations.find_by!(display_id: conversation.display_id)
  puts "✅ Step 1: Conversation found in database"
rescue => e
  puts "❌ Step 1 FAILED: #{e.message}"
  exit 1
end

# Step 2: Does Pundit policy allow it?
# The controller has: authorize @conversation.inbox, :show?
# Let's simulate this

puts "\n==== Checking Pundit Authorization ===="

# Simulate Current.account (needed for assigned_inboxes)
Current.account = account

# Check if user has access to the inbox
user_inboxes = user.assigned_inboxes.pluck(:id)
puts "User has access to inboxes: #{user_inboxes.inspect}"
puts "Conversation inbox: #{found_conv.inbox_id}"

if user_inboxes.include?(found_conv.inbox_id)
  puts "✅ User has access to this inbox"
else
  puts "❌ User does NOT have access to this inbox"
  puts "   (Should not be able to see this conversation)"
end

# Step 3: Apply permission filter
puts "\n==== Checking Permission Filter ===="

filtered = Conversations::PermissionFilterService.new(
  Conversation.where(id: found_conv.id),
  user,
  account
).perform

if filtered.exists?
  puts "❌ PROBLEM: PermissionFilterService ALLOWED this conversation!"
  puts "   User with conversation_participating_manage can access conversation assigned to someone else"
  puts "   This is the BUG!"
else
  puts "✅ PermissionFilterService correctly BLOCKED this conversation"
  puts "   But the controller might not be checking this..."
end

# Step 4: Check what ConversationPolicy allows
puts "\n==== Checking ConversationPolicy ===="

begin
  # Load the policy
  policy = ConversationPolicy.new(account_user, found_conv)

  # Check if show? is allowed
  if policy.respond_to?(:show?)
    allowed = policy.show?
    puts "Policy.show? returned: #{allowed}"
  else
    puts "⚠️  ConversationPolicy has no show? method (defaults to true in ApplicationPolicy)"
  end

  # Check if update? is allowed
  if policy.respond_to?(:update?)
    allowed = policy.update?
    puts "Policy.update? returned: #{allowed}"
  else
    puts "⚠️  ConversationPolicy has no update? method"
  end

rescue => e
  puts "Error checking policy: #{e.message}"
end

puts "\n==== Analysis ===="
puts "The controller at app/controllers/api/v1/accounts/conversations_controller.rb"
puts "authorizes the INBOX, not the CONVERSATION itself!"
puts ""
puts "Line 162-164:"
puts "  def conversation"
puts "    @conversation ||= Current.account.conversations.find_by!(display_id: params[:id])"
puts "    authorize @conversation.inbox, :show?  # <-- Only checks inbox access!"
puts "  end"
puts ""
puts "This allows ANY user with inbox access to see ANY conversation in that inbox,"
puts "regardless of conversation_participating_manage permission!"
puts ""
puts "FIX: Need to add permission check in the 'show' and 'update' actions!"

puts "\n==== Testing complete ===="
