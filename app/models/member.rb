class Member < ApplicationRecord
  has_many :attendances, dependent: :destroy
  has_many :events, through: :attendances
  has_many :submitted_appeals, class_name: 'Appeal', foreign_key: 'submitting_member_id'
  has_many :reviewed_appeals, class_name: 'Appeal', foreign_key: 'reviewed_by_member_id'

  validates :uin, presence: true, uniqueness: true
  validates :tamu_email, presence: true, uniqueness: true
  validates :name, presence: true
end
