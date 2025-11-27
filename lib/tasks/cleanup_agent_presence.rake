# frozen_string_literal: true

namespace :chatwoot do
  desc 'Cleanup agent presence - Force offline and regenerate tokens for problematic agents'
  task cleanup_agent_presence: :environment do
    puts "Starting agent presence cleanup..."

    # Opção 1: Limpar agente específico
    if ENV['USER_EMAIL'].present?
      user = User.find_by(email: ENV['USER_EMAIL'])
      if user
        cleanup_user_presence(user)
        puts "✓ Cleaned up user: #{user.email}"
      else
        puts "✗ User not found: #{ENV['USER_EMAIL']}"
      end
      next
    end

    # Opção 2: Limpar todos os agentes com auto_offline = true que estão "online" no DB
    count = 0
    AccountUser.includes(:user)
               .where(auto_offline: true, availability: 'online')
               .find_each do |account_user|
      cleanup_user_presence(account_user.user)
      count += 1
      print "." if count % 10 == 0
    end

    puts "\n✓ Cleaned up #{count} agents"
  end

  desc 'Force all agents offline in Redis (keeps DB availability)'
  task force_all_agents_offline: :environment do
    puts "Forcing all agents offline in Redis..."

    Account.find_each do |account|
      # Limpar presença de todos usuários
      redis_key = "ONLINE_PRESENCE::#{account.id}::USERS"
      Redis::Alfred.delete(redis_key)

      # Setar todos como offline no Redis
      account.account_users.each do |account_user|
        OnlineStatusTracker.set_status(account.id, account_user.user_id, 'offline')
      end

      puts "✓ Account #{account.id}: Cleared presence"
    end

    puts "✓ Done"
  end

  desc 'Regenerate pubsub tokens for all users (or specific account with ACCOUNT_ID=1)'
  task regenerate_pubsub_tokens: :environment do
    if ENV['ACCOUNT_ID'].present?
      account_id = ENV['ACCOUNT_ID'].to_i
      puts "Regenerating pubsub tokens for Account #{account_id}..."

      user_ids = AccountUser.where(account_id: account_id).pluck(:user_id)
      users = User.where(id: user_ids)

      count = 0
      users.find_each do |user|
        user.regenerate_pubsub_token
        user.save!

        # Limpar Redis para esta conta
        OnlineStatusTracker.set_status(account_id, user.id, 'offline')

        count += 1
        puts "✓ #{count}. #{user.email}" if count <= 10 || count % 10 == 0
      end

      puts "\n✓ Regenerated #{count} tokens for Account #{account_id}"
    else
      puts "Regenerating pubsub tokens for ALL users..."

      count = 0
      User.find_each do |user|
        user.regenerate_pubsub_token
        user.save!
        count += 1
        print "." if count % 50 == 0
      end

      puts "\n✓ Regenerated #{count} tokens"
    end
  end

  desc 'Regenerate pubsub tokens and clear Redis for specific account'
  task regenerate_account_tokens: :environment do
    unless ENV['ACCOUNT_ID'].present?
      puts "❌ Error: ACCOUNT_ID is required"
      puts "Usage: bundle exec rake chatwoot:regenerate_account_tokens ACCOUNT_ID=1"
      exit 1
    end

    account_id = ENV['ACCOUNT_ID'].to_i
    account = Account.find_by(id: account_id)

    unless account
      puts "❌ Error: Account #{account_id} not found"
      exit 1
    end

    puts "🔄 Regenerating tokens for Account: #{account.name} (ID: #{account_id})"
    puts "=" * 60

    user_ids = AccountUser.where(account_id: account_id).pluck(:user_id)
    users = User.where(id: user_ids)

    puts "📊 Found #{users.count} users"
    puts ""

    count = 0
    users.find_each do |user|
      # Regenerar pubsub_token
      old_token = user.pubsub_token
      user.regenerate_pubsub_token
      user.save!

      # Limpar presença no Redis
      OnlineStatusTracker.set_status(account_id, user.id, 'offline')

      count += 1
      puts "✓ #{count.to_s.rjust(3)}. #{user.email.ljust(40)} (token changed)"
    end

    # Limpar toda presença da conta no Redis
    redis_key = "ONLINE_PRESENCE::#{account_id}::USERS"
    Redis::Alfred.delete(redis_key)

    puts ""
    puts "=" * 60
    puts "✅ Completed: #{count} tokens regenerated"
    puts "✅ Redis cleared for Account #{account_id}"
    puts ""
    puts "ℹ️  All users will need to refresh their browsers to reconnect"
  end

  private

  def cleanup_user_presence(user)
    return unless user

    # Regenerar pubsub_token (invalida conexões antigas)
    user.regenerate_pubsub_token
    user.save!

    # Limpar presença no Redis para todas as contas do usuário
    user.account_users.each do |account_user|
      account_id = account_user.account_id
      user_id = user.id

      # Remover da presença
      redis_key = "ONLINE_PRESENCE::#{account_id}::USERS"
      Redis::Alfred.zrem(redis_key, user_id)

      # Setar como offline
      OnlineStatusTracker.set_status(account_id, user_id, 'offline')
    end
  rescue StandardError => e
    Rails.logger.error "Error cleaning up user #{user.id}: #{e.message}"
  end
end
