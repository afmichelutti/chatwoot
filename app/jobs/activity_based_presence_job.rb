class ActivityBasedPresenceJob < ApplicationJob
  queue_as :low

  def perform
    Rails.logger.info '[ActivityPresence] Starting job...'

    Account.where(activity_based_presence_enabled: true).find_each do |account|
      process_account_agents(account)
    end

    Rails.logger.info '[ActivityPresence] Job completed'
  end

  private

  def process_account_agents(account)
    config = account.activity_based_presence_config.with_indifferent_access
    inactivity_timeout = config[:inactivity_timeout_minutes].to_i.minutes
    busy_timeout = config[:busy_timeout_hours].to_i.hours

    Rails.logger.info "[ActivityPresence] Processing account #{account.id} (#{account.name})"

    updated_count = 0

    account.account_users.where(auto_offline: false).find_each do |account_user|
      new_status = calculate_status(account_user, inactivity_timeout, busy_timeout)

      if new_status != account_user.availability
        Rails.logger.info(
          "[ActivityPresence] User #{account_user.user.email}: #{account_user.availability} → #{new_status}"
        )

        account_user.update!(availability: new_status)
        updated_count += 1
      end
    end

    Rails.logger.info "[ActivityPresence] Account #{account.id}: #{updated_count} agents updated"
  end

  def calculate_status(account_user, inactivity_timeout, busy_timeout)
    last_message = find_last_outgoing_message(account_user)

    Rails.logger.info(
      "[ActivityPresence] #{account_user.user.email}: " \
      "last_msg=#{last_message&.created_at}, " \
      "timeout=#{inactivity_timeout.ago}, " \
      "current_status=#{account_user.availability}"
    )

    # REGRA 1: Enviou mensagem recentemente → ONLINE
    if last_message && last_message.created_at > inactivity_timeout.ago
      Rails.logger.info "[ActivityPresence] #{account_user.user.email}: REGRA 1 aplicada → ONLINE"
      return 'online'
    end

    # REGRA 2: Está em BUSY há mais de X horas → OFFLINE (esqueceu de voltar)
    if account_user.availability == 'busy' &&
       account_user.updated_at < busy_timeout.ago
      Rails.logger.info(
        "[ActivityPresence] User #{account_user.user_id} in BUSY for " \
        "#{((Time.zone.now - account_user.updated_at) / 1.hour).round(1)}h → forcing OFFLINE"
      )
      return 'offline'
    end

    # REGRA 3: Está em BUSY e < X horas → Manter BUSY (respeitar pausa)
    if account_user.availability == 'busy'
      Rails.logger.info "[ActivityPresence] #{account_user.user.email}: REGRA 3 aplicada → Manter BUSY"
      return 'busy'
    end

    # REGRA 4: Sem mensagem há muito tempo → OFFLINE
    Rails.logger.info "[ActivityPresence] #{account_user.user.email}: REGRA 4 aplicada → OFFLINE"
    'offline'
  end

  def find_last_outgoing_message(account_user)
    # Busca a última mensagem enviada pelo agente
    # Note: Removemos o filtro de message_type pois ele estava causando problemas
    # Note: Usando reorder para forçar a ordenação correta (remover default_scope order)
    Message.where(
      account_id: account_user.account_id,
      sender_id: account_user.user_id,
      sender_type: 'User'
    ).reorder('created_at DESC').limit(1).first
  end
end
