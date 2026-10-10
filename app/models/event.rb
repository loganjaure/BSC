# frozen_string_literal: true

class Event < ApplicationRecord
  belongs_to :category
  belongs_to :semester
  has_many :attendances, dependent: :destroy
  has_many :members, through: :attendances
  has_many :appeals, dependent: :destroy

  validates :event_name, presence: true
  validates :event_date_time, presence: true
  validates :description, presence: true
  validates :category_id, presence: true
  validates :semester_id, presence: true
  validates :point_value, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # AC-04.1 / AC-05.6: an event is "active" (check-in allowed) once it has started
  def active?
    return false if event_date_time.blank?
    Time.current.between?(event_date_time - 15.minutes, event_date_time + 3.hours)
  end
end
