
# frozen_string_literal: true

class Category < ApplicationRecord
  has_many :events
  has_many :semester_requirements, dependent: :restrict_with_error

  validates :category_name, presence: true, uniqueness: true
end