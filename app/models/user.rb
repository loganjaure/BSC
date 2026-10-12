# frozen_string_literal: true

class User < ApplicationRecord
  has_one :member, dependent: :destroy

  normalizes :email, with: ->(email) { email.strip.downcase }
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validate :must_be_tamu_email

  def archived?
    persisted? && Member.archived.where(user_id: id).exists?
  end

  def self.from_google(email:, full_name:, uid:, provider:)
    email = email.to_s.strip.downcase
    return nil unless valid_google_credentials?(email, uid, provider)

    transaction do
      # Google UID survives email changes. Only unclaimed seed accounts may link by email.
      user = find_google_user(email, uid, provider)
      next if user.archived? || !user.accepts_google_identity?(uid, provider)

      user.assign_attributes(email: email, full_name: full_name, uid: uid, provider: provider)
      user.save ? user : nil
    end
  rescue ActiveRecord::RecordNotUnique
    # A concurrent callback claimed this identity; the user can retry sign-in.
    nil
  end

  def self.valid_google_credentials?(email, uid, provider)
    email.match?(/\A[^\s@]+@tamu\.edu\z/) && uid.present? && provider == 'google_oauth2'
  end

  def self.find_google_user(email, uid, provider)
    lock.find_by(provider: provider, uid: uid) || lock.find_by('LOWER(email) = ?', email) || new(email: email)
  end

  private_class_method :valid_google_credentials?, :find_google_user

  def accepts_google_identity?(google_uid, google_provider)
    uid.blank? || (uid == google_uid && provider == google_provider)
  end

  private

  def must_be_tamu_email
    errors.add(:email, 'must be an official TAMU email (@tamu.edu)') unless email.to_s.match?(/\A[^\s@]+@tamu\.edu\z/)
  end
end
