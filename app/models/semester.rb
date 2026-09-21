# frozen_string_literal: true

class Semester < ApplicationRecord
  has_many :events, dependent: :destroy
  has_many :semester_requirements, dependent: :destroy

  validates :term_name, presence: true, uniqueness: true
end
