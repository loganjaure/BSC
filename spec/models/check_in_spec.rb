# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CheckIn, type: :model do
  it 'is valid with a member_id and event_id' do
    check_in = CheckIn.new(member_id: 1, event_id: 100)
    expect(check_in).to be_valid
  end

  it 'is invalid without a member_id' do
    check_in = CheckIn.new(event_id: 100)
    expect(check_in).not_to be_valid
  end
end
