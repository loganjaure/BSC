# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Appeal, type: :model do
  describe 'Associations' do
    it { should belong_to(:submitting_member).class_name('Member').with_foreign_key('submitting_member_id') }
    it { should belong_to(:reviewed_by_member).class_name('Member').with_foreign_key('reviewed_by_member_id').optional }
    it { should belong_to(:event) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:appeal_type) }
    it { should validate_presence_of(:reason) }
  end
  describe 'review statuses' do
    it 'defaults new appeals to pending' do
      expect(described_class.new).to be_pending
    end

    it 'normalizes status capitalization' do
      expect(described_class.new(status: ' Approved ').status).to eq('approved')
    end

    it 'treats a missing status as pending' do
      expect(described_class.new(status: nil)).to be_pending
    end

    it 'rejects unsupported statuses' do
      appeal = described_class.new(status: 'unrecognized')
      appeal.valid?
      expect(appeal.errors[:status]).to be_present
    end
  end
end
