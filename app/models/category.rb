# frozen_string_literal: true

class Category < ApplicationRecord
  has_many :events, dependent: :destroy
  has_many :semester_requirements, dependent: :destroy

  validates :category_name, presence: true, uniqueness: true
end
