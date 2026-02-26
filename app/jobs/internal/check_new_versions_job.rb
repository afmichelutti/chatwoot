# [NO-OP] Desabilitado na versão customizada - não faz chamadas ao ChatwootHub
class Internal::CheckNewVersionsJob < ApplicationJob
  queue_as :scheduled_jobs

  def perform; end
end

Internal::CheckNewVersionsJob.prepend_mod_with('Internal::CheckNewVersionsJob')
