class Conversations::PermissionFilterService
  attr_reader :conversations, :user, :account

  def initialize(conversations, user, account)
    @conversations = conversations
    @user = user
    @account = account
  end

  def perform
    return conversations if user_role == 'administrator'

    # Basic agents (role='agent', no custom role) are restricted to their own
    # assigned conversations plus unassigned ones within their accessible inboxes.
    # Custom-role agents are handled by the enterprise module override.
    return agent_restricted_conversations if basic_agent?

    accessible_conversations
  end

  private

  def basic_agent?
    user_role == 'agent' && account_user&.custom_role_id.blank?
  end

  def agent_restricted_conversations
    mine = accessible_conversations.assigned_to(user)
    unassigned = accessible_conversations.unassigned

    Conversation.from("(#{mine.to_sql} UNION #{unassigned.to_sql}) as conversations")
                .where(account_id: account.id)
  end

  def accessible_conversations
    conversations.where(inbox: user.inboxes.where(account_id: account.id))
  end

  def account_user
    AccountUser.find_by(account_id: account.id, user_id: user.id)
  end

  def user_role
    account_user&.role
  end
end

Conversations::PermissionFilterService.prepend_mod_with('Conversations::PermissionFilterService')
