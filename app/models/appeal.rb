class Appeal < ApplicationRecord
  belongs_to :submitting_member, class_name: 'Member', foreign_key: 'submitting_member_id'
  belongs_to :reviewed_by_member, class_name: 'Member', foreign_key: 'reviewed_by_member_id', optional: true
  belongs_to :event

  validates :appeal_type, presence: true
  validates :reason, presence: true
end