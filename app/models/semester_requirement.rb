# frozen_string_literal: true

class SemesterRequirement < ApplicationRecord
  belongs_to :semester
  belongs_to :category

  validates :required_count, presence: true, numericality: { greater_than_or_equal_to: 0 }
end
