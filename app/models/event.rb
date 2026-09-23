# frozen_string_literal: true

class Event < ApplicationRecord
  belongs_to :category
  belongs_to :semester
  has_many :attendances, dependent: :destroy
  has_many :members, through: :attendances
  has_many :appeals, dependent: :destroy

  validates :event_name, presence: true
  validates :event_date_time, presence: true
  validates :point_value, numericality: { greater_than_or_equal_to: 0 }
end
