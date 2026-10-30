# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Appeal, type: :model do
  describe 'Associations' do
    it { should belong_to(:submitting_member).class_name('Member').with_foreign_key('submitting_member_id') }
    it { should belong_to(:reviewed_by_member).class_name('Member').with_foreign_key('reviewed_by_member_id').optional }
    it { should belong_to(:event) }
  end

  describe 'Validations' do
    it 'defaults a missing appeal type to attendance before validation' do
      appeal = described_class.new(appeal_type: nil)

      appeal.valid?

      expect(appeal.appeal_type).to eq('attendance')
      expect(appeal.errors[:appeal_type]).to be_empty
    end

    [ '', '   ' ].each do |blank_type|
      it "rejects a blank appeal type: #{blank_type.inspect}" do
        appeal = described_class.new(appeal_type: blank_type)

        appeal.valid?

        expect(appeal.errors[:appeal_type]).to include("can't be blank")
      end
    end

    it do
      should validate_presence_of(:reason).with_message('cannot be empty')
    end
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
