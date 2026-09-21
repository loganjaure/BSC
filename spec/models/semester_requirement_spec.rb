require 'rails_helper'

RSpec.describe SemesterRequirement, type: :model do
  describe 'Associations' do
    it { should belong_to(:semester) }
    it { should belong_to(:category) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:required_count) }
    it { should validate_numericality_of(:required_count).is_greater_than_or_equal_to(0) }
  end
end