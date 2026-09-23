class Member < ApplicationRecord
  belongs_to :user, optional: true

  has_many :attendances, dependent: :destroy
  has_many :events, through: :attendances
  has_many :submitted_appeals, class_name: "Appeal", foreign_key: "submitting_member_id"
  has_many :reviewed_appeals, class_name: "Appeal", foreign_key: "reviewed_by_member_id"

  validates :name, presence: { message: "cannot be blank" }

  validates :tamu_email, presence: true, uniqueness: true

  validates :uin, presence: { message: "cannot be blank" }, numericality: { only_integer: true, message: "must be numeric " }, length: { is: 9, message: "must be exactly 9 digits" }, uniqueness: { case_sensitive: false }, on: :update

  validates :class_year, presence: { message: "cannot be blank" }, numericality: { only_integer: true, greater_than: 2000, less_than: 2100, message: "must be a valid 4-digit year" }, on: :update
end
