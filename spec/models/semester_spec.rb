# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Semester, type: :model do
  describe 'Associations' do
    it { should have_many(:events) }
    it { should have_many(:semester_requirements) }
  end

  describe 'Validations' do
    subject { Semester.new(term_name: 'Fall 2026') }

    it { should validate_presence_of(:term_name) }
    it { should validate_uniqueness_of(:term_name) }
  end

  describe '.current' do
    it 'returns nil when no semesters exist' do
      expect(Semester.current).to be_nil
    end

    it 'returns the most recently created semester' do
      Semester.create!(term_name: 'Spring 2026')
      newest = Semester.create!(term_name: 'Fall 2026')

      expect(Semester.current).to eq(newest)
    end
  end
end
