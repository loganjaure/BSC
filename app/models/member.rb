class Member < ApplicationRecord
  belongs_to :user, optional: true

  has_many :attendances, dependent: :destroy
  has_many :events, through: :attendances
  has_many :submitted_appeals, class_name: 'Appeal', foreign_key: 'submitting_member_id' # rubocop:todo Rails/InverseOf
  has_many :reviewed_appeals, class_name: 'Appeal', foreign_key: 'reviewed_by_member_id' # rubocop:todo Rails/InverseOf

  validates :name, presence: { message: 'cannot be blank' }

  scope :active, -> { where(archived_at: nil) }
  scope :archived, -> { where.not(archived_at: nil) }

  # This virtual field keeps rejected input on the form without storing a stale total.
  attribute :requested_total_points, :string

  normalizes :tamu_email, with: ->(email) { email.strip.downcase }
  validates :tamu_email, presence: true, uniqueness: { case_sensitive: false },
                         format: { with: /\A[^\s@]+@tamu\.edu\z/, message: 'must be an official TAMU email (@tamu.edu)' }
  validates :requested_total_points, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :points_adjustment, numericality: true

  before_save :apply_requested_total_points, if: -> { requested_total_points.present? }
  after_save :clear_requested_total_points

  validates :uin, presence: { message: 'cannot be blank' }, numericality: { only_integer: true, message: 'must be numeric ' }, length: { is: 9, message: 'must be exactly 9 digits' }, uniqueness: { case_sensitive: false }, on: :update

  validates :class_year, presence: { message: 'cannot be blank' }, numericality: { only_integer: true, greater_than: 2000, less_than: 2100, message: 'must be a valid 4-digit year' }, on: :update
  def archived?
    archived_at.present?
  end

  # Attendance continues to accrue after an administrator corrects the total.
  def total_points
    attendance_points + points_adjustment
  end

  def total_points=(value)
    self.requested_total_points = value.to_s
  end

  def attendance_points
    events.sum(:point_value)
  end

  private

  def apply_requested_total_points
    self.points_adjustment = BigDecimal(requested_total_points) - attendance_points
  end

  def clear_requested_total_points
    self.requested_total_points = nil
    clear_attribute_change('requested_total_points')
  end
end
