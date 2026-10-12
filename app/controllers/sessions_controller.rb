# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :require_login, only: %i[create failure]

  def create
    auth = request.env['omniauth.auth']
    unless auth&.info&.email.to_s.strip.downcase.match?(/\A[^\s@]+@tamu\.edu\z/)
      redirect_to root_path, alert: 'Access denied: You must use an official @tamu.edu email address.'
      return
    end

    member = authenticate_member(auth)
    return sign_in_failed unless member

    if member.uin.blank?
      redirect_to edit_member_path(member), notice: 'Please complete your profile by providing your UIN and Class Year.'
    else
      redirect_to dashboard_path, notice: 'Successfully signed in!'
    end
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique
    sign_in_failed
  end

  def destroy
    reset_session
    redirect_to root_path, notice: 'Logged out successfully.'
  end

  def failure
    redirect_to root_path, alert: 'Sign-in was canceled or failed. Please try again.'
  end

  private

  def authenticate_member(auth)
    User.transaction do
      user = User.from_google(email: auth.info.email, full_name: auth.info.name, uid: auth.uid, provider: auth.provider)
      next unless user&.persisted?

      # The association is authoritative: an administrator may have edited the roster email.
      member = user.member || user.build_member(name: user.full_name, tamu_email: user.email)
      member.save! if member.new_record?
      member.lock!
      next if member.archived?

      reset_session
      session[:user_id] = user.id
      member
    end
  end

  def sign_in_failed
    reset_session
    redirect_to root_path, alert: 'Unable to sign in. Contact a BSC administrator if your membership has been archived.'
  end
end
