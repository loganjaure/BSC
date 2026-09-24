class User < ApplicationRecord
  # Association with member model
  has_one :member, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validate :must_be_tamu_email

  def self.from_google(email:, full_name:, uid:, provider:)
    # AC-01.2: Restrict non-TAMU emails
    return nil unless email.to_s.downcase.end_with?("@tamu.edu")

    # AC-01.4: Find existing user by email instead of creating duplicate accounts
    user = find_or_create_by(email: email.downcase) do |u|
      u.uid = uid
      u.provider = provider
      u.full_name = full_name
    end

    # Update attributes in case provider info was missing
    user.update(uid: uid, provider: provider, full_name: full_name) if user.persisted?
    user
  end

  private

  def must_be_tamu_email
    unless email.to_s.downcase.end_with?("@tamu.edu")
      errors.add(:email, "must be an official TAMU email (@tamu.edu)")
    end
  end
end
