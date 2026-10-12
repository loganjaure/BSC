# frozen_string_literal: true

class Attendance < ApplicationRecord
  belongs_to :member
  belongs_to :event

  validates :member_id, presence: true
  validates :event_id, presence: true

  before_create :lock_active_member

  private

  def lock_active_member
    # Serialize check-ins with point corrections and archival until the save commits.
    member.lock!
    return unless member.archived?

    errors.add(:member, 'has been archived')
    throw :abort
  end
end
