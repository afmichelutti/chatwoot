require 'rails_helper'

RSpec.describe Conversations::PermissionFilterService do
  let(:account) { create(:account) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:other_agent) { create(:user, account: account, role: :agent) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let!(:inbox) { create(:inbox, account: account) }
  let!(:other_inbox) { create(:inbox, account: account) }

  let!(:assigned_to_agent) { create(:conversation, account: account, inbox: inbox, assignee: agent) }
  let!(:unassigned_conversation) { create(:conversation, account: account, inbox: inbox, assignee: nil) }
  let!(:assigned_to_other) { create(:conversation, account: account, inbox: inbox, assignee: other_agent) }
  let!(:other_inbox_conversation) { create(:conversation, account: account, inbox: other_inbox) }

  # Agent has access to inbox but NOT other_inbox
  before { create(:inbox_member, user: agent, inbox: inbox) }

  describe '#perform' do
    context 'when user is an administrator' do
      it 'returns all conversations without restriction' do
        result = described_class.new(
          account.conversations,
          admin,
          account
        ).perform

        expect(result).to include(assigned_to_agent)
        expect(result).to include(unassigned_conversation)
        expect(result).to include(assigned_to_other)
        expect(result).to include(other_inbox_conversation)
        expect(result.count).to eq(4)
      end
    end

    context 'when user is a basic agent (no custom role)' do
      it 'returns only their assigned conversations and unassigned ones within their inboxes' do
        result = described_class.new(
          account.conversations,
          agent,
          account
        ).perform

        expect(result).to include(assigned_to_agent)
        expect(result).to include(unassigned_conversation)
        expect(result).not_to include(assigned_to_other)
        expect(result).not_to include(other_inbox_conversation)
        expect(result.count).to eq(2)
      end

      it 'does not expose conversations assigned to other agents' do
        result = described_class.new(
          account.conversations,
          agent,
          account
        ).perform

        expect(result).not_to include(assigned_to_other)
      end

      it 'does not expose conversations in inboxes the agent does not belong to' do
        result = described_class.new(
          account.conversations,
          agent,
          account
        ).perform

        expect(result).not_to include(other_inbox_conversation)
      end
    end
  end
end
