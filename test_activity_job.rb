# Test script to simulate ActivityBasedPresenceJob behavior
puts "=" * 80
puts "TESTING ACTIVITY-BASED PRESENCE JOB"
puts "=" * 80

account_id = 1
user_id = 1

# Get the account user
account_user = AccountUser.find_by(account_id: account_id, user_id: user_id)

if account_user.nil?
  puts "❌ AccountUser not found!"
  exit
end

puts "\n📋 ACCOUNT USER INFO:"
puts "  Email: #{account_user.user.email}"
puts "  Current Status: #{account_user.availability}"
puts "  Auto Offline: #{account_user.auto_offline}"
puts "  Updated At: #{account_user.updated_at}"

if account_user.auto_offline
  puts "\n⚠️  AUTO_OFFLINE IS TRUE - This user will be IGNORED by the job!"
  puts "   Set auto_offline=false to enable activity-based presence"
  exit
end

# Get account config
account = account_user.account
puts "\n📋 ACCOUNT CONFIG:"
puts "  Activity Enabled: #{account.activity_based_presence_enabled}"
puts "  Config: #{account.activity_based_presence_config.inspect}"

unless account.activity_based_presence_enabled
  puts "\n⚠️  ACTIVITY-BASED PRESENCE IS DISABLED FOR THIS ACCOUNT!"
  exit
end

config = account.activity_based_presence_config.with_indifferent_access
inactivity_timeout = config[:inactivity_timeout_minutes].to_i.minutes
busy_timeout = config[:busy_timeout_hours].to_i.hours

puts "\n⏱️  TIMEOUTS:"
puts "  Inactivity: #{config[:inactivity_timeout_minutes]} minutes"
puts "  Busy: #{config[:busy_timeout_hours]} hours"

# Find last message - EXACTLY as the job does it
puts "\n🔍 SEARCHING FOR LAST MESSAGE..."
puts "  Query conditions:"
puts "    account_id: #{account_user.account_id}"
puts "    sender_id: #{account_user.user_id}"
puts "    sender_type: 'User'"

last_message = Message.where(
  account_id: account_user.account_id,
  sender_id: account_user.user_id,
  sender_type: 'User'
).reorder('created_at DESC').limit(1).first

puts "\n📨 LAST MESSAGE FOUND:"
if last_message
  puts "  ✅ Message ID: #{last_message.id}"
  puts "  Content: #{last_message.content&.truncate(50)}"
  puts "  Created: #{last_message.created_at}"
  puts "  Message Type: #{last_message.message_type}"
  puts "  Sender ID: #{last_message.sender_id}"
  puts "  Sender Type: #{last_message.sender_type}"
else
  puts "  ❌ NO MESSAGE FOUND!"
end

# Calculate what the status should be
puts "\n🧮 CALCULATING STATUS..."
puts "  Current time: #{Time.zone.now}"
puts "  Inactivity threshold: #{inactivity_timeout.ago}"

new_status = nil

# REGRA 1: Enviou mensagem recentemente → ONLINE
if last_message && last_message.created_at > inactivity_timeout.ago
  puts "\n✅ REGRA 1: Message within timeout → ONLINE"
  puts "  Last message: #{last_message.created_at}"
  puts "  Timeout: #{inactivity_timeout.ago}"
  puts "  Difference: #{((Time.zone.now - last_message.created_at) / 60).round(2)} minutes ago"
  new_status = 'online'
# REGRA 2: Está em BUSY há mais de X horas → OFFLINE
elsif account_user.availability == 'busy' && account_user.updated_at < busy_timeout.ago
  puts "\n✅ REGRA 2: BUSY for too long → OFFLINE"
  puts "  In BUSY for: #{((Time.zone.now - account_user.updated_at) / 1.hour).round(1)} hours"
  new_status = 'offline'
# REGRA 3: Está em BUSY e < X horas → Manter BUSY
elsif account_user.availability == 'busy'
  puts "\n✅ REGRA 3: Still in BUSY (under limit) → Keep BUSY"
  new_status = 'busy'
# REGRA 4: Sem mensagem há muito tempo → OFFLINE
else
  puts "\n✅ REGRA 4: No recent message → OFFLINE"
  if last_message
    puts "  Last message was #{((Time.zone.now - last_message.created_at) / 60).round(2)} minutes ago"
    puts "  Timeout is #{config[:inactivity_timeout_minutes]} minutes"
  else
    puts "  No messages found at all"
  end
  new_status = 'offline'
end

puts "\n📊 RESULT:"
puts "  Current Status: #{account_user.availability}"
puts "  New Status: #{new_status}"

if new_status != account_user.availability
  puts "  ➡️  STATUS WOULD CHANGE: #{account_user.availability} → #{new_status}"
else
  puts "  ➡️  NO CHANGE NEEDED (already #{new_status})"
end

puts "\n" + "=" * 80
