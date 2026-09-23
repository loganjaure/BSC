# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Attendance, type: :model do
  describe 'Associations' do
    it { should belong_to(:member) }
    it { should belong_to(:event) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:member_id) }
    it { should validate_presence_of(:event_id) }
  end
end
