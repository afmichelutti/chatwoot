class SetAutoOfflineToTrue < ActiveRecord::Migration[7.0]
  def up
    # Atualiza todos os account_users para auto_offline = true
    AccountUser.where(auto_offline: false).update_all(auto_offline: true)

    # Opcional: imprimir resultado
    Rails.logger.info "Updated #{AccountUser.where(auto_offline: true).count} account_users to auto_offline = true"
  end

  def down
    # Rollback não faz nada, pois não sabemos quais eram false antes
    # Se quiser, pode setar todos para false:
    # AccountUser.update_all(auto_offline: false)
  end
end
