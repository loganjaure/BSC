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
end
