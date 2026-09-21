require 'rails_helper'

RSpec.describe Event, type: :model do
  describe 'Associations' do
    it { should belong_to(:category) }
    it { should belong_to(:semester) }
    it { should have_many(:attendances) }
    it { should have_many(:members).through(:attendances) }
    it { should have_many(:appeals) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:event_name) }
    it { should validate_presence_of(:event_date_time) }
    it { should validate_numericality_of(:point_value).is_greater_than_or_equal_to(0) }
  end
end