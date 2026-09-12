# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CheckIn, type: :model do
  describe 'validations' do
    it 'is valid with member_id and event_id' do
      member = Member.create!(name: 'Test Member')
      event = Event.create!(title: 'Test Event')
      check_in = CheckIn.new(member: member, event: event)
      expect(check_in).to be_valid
    end

    it 'is invalid without a member_id' do
      event = Event.create!(title: 'Test Event')
      check_in = CheckIn.new(member_id: nil, event: event)
      expect(check_in).not_to be_valid
    end

    it 'is invalid without an event_id' do
      member = Member.create!(name: 'Test Member')
      check_in = CheckIn.new(member: member, event_id: nil)
      expect(check_in).not_to be_valid
    end
  end

  describe 'associations' do
    it 'belongs to a member' do
      association = described_class.reflect_on_association(:member)
      expect(association.macro).to eq :belongs_to
    end

    it 'belongs to an event' do
      association = described_class.reflect_on_association(:event)
      expect(association.macro).to eq :belongs_to
    end
  end
end
