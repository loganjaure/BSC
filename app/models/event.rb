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

    check_in_opens_at = event_date_time - check_in_opens_minutes_before.minutes

    check_in_closes_at = event_date_time + check_in_closes_minutes_after.minutes

    Time.current.between?(check_in_opens_at, check_in_closes_at)
  end


  # Optional event-specific check-in code
  def valid_check_in_code?(submitted_code)
    return true if check_in_code.blank?
    return false if submitted_code.blank?

    expected = Digest::SHA256.hexdigest(check_in_code)
    submitted = Digest::SHA256.hexdigest(submitted_code)

    ActiveSupport::SecurityUtils.secure_compare(expected, submitted)
  end
end
