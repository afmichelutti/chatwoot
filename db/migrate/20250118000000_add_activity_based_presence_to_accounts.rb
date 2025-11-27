class AddActivityBasedPresenceToAccounts < ActiveRecord::Migration[7.0]
  def change
    add_column :accounts, :activity_based_presence_enabled, :boolean, default: false, null: false
    add_column :accounts, :activity_based_presence_config, :jsonb, default: {
      inactivity_timeout_minutes: 10,
      busy_timeout_hours: 3
    }, null: false
  end
end
