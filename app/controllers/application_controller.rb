# frozen_string_literal: true

class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  before_action :require_login
  before_action :ensure_profile_complete
  helper_method :current_user, :logged_in?

  private

  def current_user
    # AC-03.4: User stays logged in across refreshes/reopening
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def current_member
    @current_member ||= current_user&.member
  end

  def logged_in?
    current_user.present?
  end

  def require_login
    # AC-03.3: Block unauthenticated users
    unless logged_in?
      redirect_to root_path, alert: "Please sign in with your TAMU email to continue."
    end
  end

  def ensure_profile_complete
    return unless logged_in? && current_member

    # redirect to edit profile if UIN is missing
    if current_member.uin.blank? && !profile_action?
      redirect_to edit_member_path(current_member), alert: "Please complete your profile details to proceed."
    end
  end
  
  def profile_action?
    (controller_name == "members" && action_name.in?(%w[edit update])) || controller_name == "sessions"
  end

end
