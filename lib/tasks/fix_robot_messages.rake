# frozen_string_literal: true

namespace :chatwoot do
  desc 'Convert robot activity messages to outgoing messages to trigger automations'
  task fix_robot_messages: :environment do
    # Find messages that match the robot pattern
    # Adjust the pattern to match your robot messages
    robot_pattern = ENV['PATTERN'] || 'adicionou disparo'
    conversation_id = ENV['CONVERSATION_ID']&.to_i
    account_id = ENV['ACCOUNT_ID']&.to_i || 1
    dry_run = ENV['DRY_RUN'] != 'false'

    puts "=" * 80
    puts "🤖 FIX ROBOT MESSAGES"
    puts "=" * 80
    puts ""
    puts "Pattern: #{robot_pattern}"
    puts "Account ID: #{account_id}" if account_id
    puts "Conversation ID: #{conversation_id}" if conversation_id
    puts "Mode: #{dry_run ? '🔍 DRY RUN (no changes)' : '✍️  WRITE MODE (will update)'}"
    puts ""

    # Build query
    query = Message.where(message_type: :activity)
                   .where("content ILIKE ?", "%#{robot_pattern}%")

    query = query.where(account_id: account_id) if account_id
    query = query.where(conversation_id: conversation_id) if conversation_id

    messages = query.order(created_at: :desc)

    if messages.empty?
      puts "ℹ️  No activity messages found matching pattern '#{robot_pattern}'"
      exit 0
    end

    puts "Found #{messages.count} activity messages to convert:"
    puts ""

    messages.each_with_index do |msg, index|
      puts "#{index + 1}. Message ##{msg.id}"
      puts "   Conversation: #{msg.conversation_id}"
      puts "   Content: #{msg.content.truncate(80)}"
      puts "   Created: #{msg.created_at}"
      puts "   Current Type: activity (2)"
      puts ""
    end

    if dry_run
      puts "=" * 80
      puts "🔍 DRY RUN - No changes made"
      puts "To actually convert these messages, run:"
      puts "bundle exec rake chatwoot:fix_robot_messages DRY_RUN=false PATTERN='#{robot_pattern}'"
      puts "=" * 80
      exit 0
    end

    # Confirm before proceeding
    print "\n⚠️  Are you sure you want to convert these #{messages.count} messages? (yes/no): "
    confirmation = STDIN.gets.chomp

    unless confirmation.downcase == 'yes'
      puts "❌ Cancelled"
      exit 0
    end

    puts ""
    puts "Converting messages..."
    puts ""

    converted = 0
    errors = 0

    messages.each do |msg|
      begin
        # Convert to outgoing message
        # Set sender to the first user in the account (you may want to adjust this)
        account_user = AccountUser.where(account_id: msg.account_id).first
        user = account_user&.user

        if user.nil?
          puts "   ⚠️  Message ##{msg.id}: No user found in account, skipping"
          errors += 1
          next
        end

        msg.update!(
          message_type: :outgoing,
          sender: user
        )

        converted += 1
        puts "   ✅ Message ##{msg.id}: Converted to outgoing"

        # Dispatch event to trigger automations for this message
        # CAUTION: This will trigger automations NOW
        if ENV['TRIGGER_AUTOMATIONS'] == 'true'
          Rails.configuration.dispatcher.dispatch(
            'message.created',
            Time.zone.now,
            message: msg,
            performed_by: nil
          )
          puts "      🎬 Automations triggered"
        end
      rescue StandardError => e
        errors += 1
        puts "   ❌ Message ##{msg.id}: Error - #{e.message}"
      end
    end

    puts ""
    puts "=" * 80
    puts "✅ COMPLETE"
    puts "   Converted: #{converted}"
    puts "   Errors: #{errors}"
    puts "=" * 80

    if converted > 0 && ENV['TRIGGER_AUTOMATIONS'] != 'true'
      puts ""
      puts "ℹ️  Note: Messages were converted but automations were NOT triggered."
      puts "   Automations will only trigger for NEW messages going forward."
      puts "   To trigger automations for these converted messages, run:"
      puts "   bundle exec rake chatwoot:fix_robot_messages DRY_RUN=false TRIGGER_AUTOMATIONS=true PATTERN='#{robot_pattern}'"
    end
  end

  desc 'Set default sender for robot messages'
  task set_robot_sender: :environment do
    unless ENV['USER_EMAIL'].present?
      puts "❌ Error: USER_EMAIL is required"
      puts "Usage: bundle exec rake chatwoot:set_robot_sender USER_EMAIL=robot@example.com"
      exit 1
    end

    user = User.find_by(email: ENV['USER_EMAIL'])

    unless user
      puts "❌ Error: User not found with email #{ENV['USER_EMAIL']}"
      exit 1
    end

    # Store in Rails credentials or environment
    puts "✅ Found user: #{user.name} (ID: #{user.id})"
    puts ""
    puts "To use this user as default sender for robot messages, add to your .env:"
    puts "ROBOT_SENDER_USER_ID=#{user.id}"
  end
end
