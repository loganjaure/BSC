# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Category, type: :model do
  describe 'Associations' do
    it { should have_many(:events) }
    it { should have_many(:semester_requirements) }
  end

  describe 'Validations' do
    subject { Category.new(category_name: 'General') }

    it { should validate_presence_of(:category_name) }
    it { should validate_uniqueness_of(:category_name) }
  end
end
