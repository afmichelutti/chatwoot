require 'rails_helper'

RSpec.describe Internal::CheckNewVersionsJob do
  it 'is a no-op' do
    expect { described_class.perform_now }.not_to raise_error
  end
end
