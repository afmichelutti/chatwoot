class UpdateAgentPresenceJob < ApplicationJob
  queue_as :high # Alta prioridade para ser quase instantâneo

  def perform(account_id, user_id)
    account_user = AccountUser.find_by(account_id: account_id, user_id: user_id)
    return unless account_user
    return if account_user.auto_offline? # Agente gerencia status manualmente
    return if account_user.availability == 'busy' # Respeita pausa intencional

    Rails.logger.info "[ActivityPresence] Immediate update: #{account_user.user.email} → ONLINE (message sent)"
    account_user.update!(availability: 'online')
  rescue StandardError => e
    Rails.logger.error "[ActivityPresence] Error updating agent presence: #{e.message}"
  end
end
