
# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Category, type: :model do
  describe 'Associations' do
    it { should have_many(:events) }
    it { should have_many(:semester_requirements) }

    it 'does not automatically destroy associated events' do
      association = described_class.reflect_on_association(:events)

      expect(association.options[:dependent]).to be_nil
    end
  end

  describe 'Validations' do
    subject { Category.new(category_name: 'General') }

    it { should validate_presence_of(:category_name) }
    it { should validate_uniqueness_of(:category_name) }
  end
end
