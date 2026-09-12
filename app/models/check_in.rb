# frozen_string_literal: true

class CheckIn < ApplicationRecord
  belongs_to :member
  belongs_to :event

  validates :member_id, :event_id, presence: true
end
