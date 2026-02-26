# Debug script for Cloves' 500 error
# Run with: bundle exec rails runner debug_cloves_error.rb

puts "==== Debugging Cloves' conversation error ===="

# Find user
user = User.find_by(email: 'cloves@caperbrasil.com.br')
if user.nil?
  puts "ERROR: User not found!"
  exit 1
end

puts "User: #{user.name} (ID: #{user.id})"

# Get account
account = Account.find(1)
puts "Account: #{account.name} (ID: #{account.id})"
puts "SLA enabled: #{account.feature_enabled?('sla') rescue 'N/A'}"

# Simulate the ConversationFinder params
params = {
  status: 'open',
  assignee_type: 'me',
  page: 1,
  sort_by: 'last_activity_at_desc'
}.with_indifferent_access

puts "\nParams: #{params.inspect}"

# Try to reproduce the error step by step
begin
  puts "\n==== Step 1: Basic conversation query ===="
  conversations = account.conversations.where(status: :open, assignee_id: user.id)
  count = conversations.count
  puts "Found #{count} open conversations assigned to Cloves"

  puts "\n==== Step 2: Add eager loading (base query) ===="

  # Check if SLA feature is enabled
  sla_enabled = account.feature_enabled?('sla') rescue false
  puts "SLA feature enabled: #{sla_enabled}"

  if sla_enabled
    conversations = conversations.includes(
      :taggings, :inbox, :applied_sla, :sla_events,
      { assignee: { avatar_attachment: [:blob] } },
      { contact: { avatar_attachment: [:blob] } },
      :team, :contact_inbox
    )
  else
    conversations = conversations.includes(
      :taggings, :inbox,
      { assignee: { avatar_attachment: [:blob] } },
      { contact: { avatar_attachment: [:blob] } },
      :team, :contact_inbox
    )
  end

  puts "Added eager loading includes"

  puts "\n==== Step 3: Add sorting ===="
  conversations = conversations.order(last_activity_at: :desc)
  puts "Added sorting by last_activity_at DESC"

  puts "\n==== Step 4: Add pagination ===="
  conversations = conversations.page(1).per(25)
  puts "Added pagination (page 1, per 25)"

  puts "\n==== Step 5: Execute query (to_a) ===="
  result = conversations.to_a
  puts "SUCCESS! Query executed, returned #{result.length} conversations"

  puts "\n==== Checking for potential data issues ===="

  # Check for orphaned SLA references
  if sla_enabled
    orphaned_sla = account.conversations
      .where.not(sla_policy_id: nil)
      .left_joins(:applied_sla)
      .where(applied_slas: { id: nil })
      .count

    puts "Conversations with sla_policy_id but no applied_sla: #{orphaned_sla}"

    if orphaned_sla > 0
      puts "WARNING: Found orphaned SLA references!"
      puts "This could cause eager loading issues."
    end
  end

  # Check for conversations without contact_inbox
  no_contact_inbox = account.conversations
    .where(status: :open, assignee_id: user.id)
    .where(contact_inbox_id: nil)
    .count

  puts "Open conversations for Cloves without contact_inbox: #{no_contact_inbox}"

  if no_contact_inbox > 0
    puts "WARNING: Found conversations without contact_inbox!"
    puts "This could cause eager loading issues."
  end

  # Check for conversations with nil last_activity_at
  nil_activity = account.conversations
    .where(status: :open, assignee_id: user.id)
    .where(last_activity_at: nil)
    .count

  puts "Open conversations for Cloves with nil last_activity_at: #{nil_activity}"

rescue => e
  puts "\n==== ERROR FOUND ===="
  puts "Error class: #{e.class.name}"
  puts "Error message: #{e.message}"
  puts "\nBacktrace:"
  puts e.backtrace.first(20).join("\n")
end

puts "\n==== Debug complete ===="
