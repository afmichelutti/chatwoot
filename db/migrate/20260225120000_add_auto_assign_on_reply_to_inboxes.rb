class AddAutoAssignOnReplyToInboxes < ActiveRecord::Migration[7.0]
  def change
    add_column :inboxes, :auto_assign_on_reply, :boolean, default: true, null: false
  end
end
