# frozen_string_literal: true

class Appeal < ApplicationRecord
  belongs_to :submitting_member, class_name: 'Member', foreign_key: 'submitting_member_id' # rubocop:todo Rails/InverseOf
  belongs_to :reviewed_by_member, class_name: 'Member', foreign_key: 'reviewed_by_member_id', optional: true # rubocop:todo Rails/InverseOf
  belongs_to :event

  STATUSES = %w[pending approved denied].freeze

  attribute :status, :string, default: 'pending'
  normalizes :status, with: ->(value) { value.to_s.strip.downcase.presence || 'pending' }, apply_to_nil: true
  scope :pending, -> { where(status: 'pending') }

  validates :status, inclusion: { in: STATUSES }

  def pending?
    status == 'pending'
  end

  validates :appeal_type, presence: true
  validates :reason, presence: true
end
