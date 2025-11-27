# frozen_string_literal: true

namespace :chatwoot do
  desc 'Debug automation rules for a specific message'
  task debug_automation: :environment do
    unless ENV['MESSAGE_ID'].present?
      puts "❌ Error: MESSAGE_ID is required"
      puts "Usage: bundle exec rake chatwoot:debug_automation MESSAGE_ID=123"
      exit 1
    end

    message_id = ENV['MESSAGE_ID'].to_i
    message = Message.find_by(id: message_id)

    unless message
      puts "❌ Error: Message #{message_id} not found"
      exit 1
    end

    puts "=" * 80
    puts "🔍 DEBUGGING AUTOMATION FOR MESSAGE #{message_id}"
    puts "=" * 80
    puts ""

    # Message details
    puts "📨 MESSAGE DETAILS:"
    puts "   ID: #{message.id}"
    puts "   Content: #{message.content&.truncate(100)}"
    puts "   Message Type: #{message.message_type} (#{message.message_type_before_type_cast})"
    puts "   Content Type: #{message.content_type}"
    puts "   Sender: #{message.sender_type} ##{message.sender_id}"
    puts "   Account ID: #{message.account_id}"
    puts "   Inbox ID: #{message.inbox_id}"
    puts "   Conversation ID: #{message.conversation_id}"
    puts "   Created At: #{message.created_at}"
    puts "   Is Activity?: #{message.activity?}"
    puts "   Is Auto Reply Email?: #{message.auto_reply_email?}"
    puts ""

    # Conversation details
    conversation = message.conversation
    puts "💬 CONVERSATION DETAILS:"
    puts "   ID: #{conversation.id}"
    puts "   Status: #{conversation.status}"
    puts "   Assignee ID: #{conversation.assignee_id}"
    puts "   Team ID: #{conversation.team_id}"
    puts "   Inbox ID: #{conversation.inbox_id}"
    puts ""

    # Find automation rules for message_created event
    rules = AutomationRule.where(
      event_name: 'message_created',
      account_id: message.account_id,
      active: true
    )

    if rules.empty?
      puts "⚠️  NO ACTIVE AUTOMATION RULES for 'message_created' event in account #{message.account_id}"
      exit 0
    end

    puts "📋 AUTOMATION RULES (#{rules.count} active):"
    puts ""

    rules.each_with_index do |rule, index|
      puts "   #{index + 1}. #{rule.name} (ID: #{rule.id})"
      puts "      Description: #{rule.description}" if rule.description.present?
      puts "      Conditions: #{rule.conditions.inspect}"
      puts "      Actions: #{rule.actions.inspect}"
      puts ""

      # Check if message would be ignored
      puts "      🔍 CHECKING IF MESSAGE WOULD BE IGNORED:"

      # Simulate ignore_message_created_event? logic
      is_activity = message.activity?
      is_auto_reply_email = message.auto_reply_email?

      if is_activity
        puts "         ❌ YES - Message is of type 'activity'"
        puts "         ℹ️  Activity messages are system messages and don't trigger automations"
        next
      elsif is_auto_reply_email
        puts "         ❌ YES - Message is an auto-reply email"
        next
      else
        puts "         ✅ NO - Message would NOT be ignored"
      end
      puts ""

      # Test conditions
      puts "      🔍 TESTING CONDITIONS:"
      begin
        conditions_match = AutomationRules::ConditionsFilterService.new(
          rule,
          conversation,
          { message: message }
        ).perform

        if conditions_match
          puts "         ✅ CONDITIONS MATCH - Automation SHOULD trigger"
          puts ""
          puts "      🎬 ACTIONS THAT WOULD BE EXECUTED:"
          rule.actions.each do |action|
            puts "         - #{action['action_name']}: #{action['action_params']}"
          end
        else
          puts "         ❌ CONDITIONS DO NOT MATCH"
          puts ""
          puts "      🔍 DETAILED CONDITION ANALYSIS:"

          rule.conditions.each_with_index do |condition, cond_index|
            puts "         #{cond_index + 1}. #{condition['attribute_key']} #{condition['filter_operator']} #{condition['values']}"

            # Check message content specifically
            if condition['attribute_key'] == 'content'
              content_downcase = message.processed_message_content&.downcase || message.content&.downcase || ""
              condition['values'].each do |search_term|
                contains = content_downcase.include?(search_term.downcase)
                if contains
                  puts "            ✅ Message content CONTAINS '#{search_term}'"
                else
                  puts "            ❌ Message content DOES NOT contain '#{search_term}'"
                end
              end
            elsif condition['attribute_key'] == 'message_type'
              actual_type = message.message_type_before_type_cast
              expected_types = condition['values']
              if expected_types.include?(actual_type.to_s) || expected_types.include?(actual_type)
                puts "            ✅ Message type matches (#{actual_type})"
              else
                puts "            ❌ Message type does NOT match (expected: #{expected_types}, actual: #{actual_type})"
              end
            end
          end
        end
      rescue StandardError => e
        puts "         ❌ ERROR TESTING CONDITIONS: #{e.message}"
        puts "         #{e.backtrace.first(3).join("\n         ")}"
      end

      puts ""
      puts "   " + "-" * 76
      puts ""
    end

    puts "=" * 80
    puts "✅ DEBUGGING COMPLETE"
    puts "=" * 80
  end

  desc 'List recent messages with their types for debugging'
  task list_recent_messages: :environment do
    account_id = ENV['ACCOUNT_ID']&.to_i || 1
    limit = ENV['LIMIT']&.to_i || 20

    puts "=" * 80
    puts "📨 RECENT MESSAGES FOR ACCOUNT #{account_id}"
    puts "=" * 80
    puts ""

    messages = Message.where(account_id: account_id)
                      .order(created_at: :desc)
                      .limit(limit)

    messages.each do |msg|
      type_indicator = case msg.message_type_before_type_cast
                       when 0 then "⬇️  IN "
                       when 1 then "⬆️  OUT"
                       when 2 then "📋 ACT"
                       when 3 then "📄 TPL"
                       else "❓ ???"
                       end

      sender_info = if msg.sender.is_a?(User)
                      "👤 #{msg.sender.name}"
                    elsif msg.sender.is_a?(Contact)
                      "👥 #{msg.sender.name}"
                    elsif msg.sender.is_a?(AgentBot)
                      "🤖 #{msg.sender.name}"
                    else
                      "❓ Unknown"
                    end

      content_preview = msg.content&.truncate(60) || "[no content]"

      puts "#{msg.id.to_s.rjust(8)} | #{type_indicator} | #{sender_info.ljust(25)} | #{content_preview}"
    end

    puts ""
    puts "Legend:"
    puts "  ⬇️  IN  = incoming (0) - Messages from customers"
    puts "  ⬆️  OUT = outgoing (1) - Messages sent by agents"
    puts "  📋 ACT = activity (2) - System messages (don't trigger automations)"
    puts "  📄 TPL = template (3) - Template messages"
  end
end
