# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :require_login
  helper_method :current_user, :logged_in?

  private

  def current_user
    # AC-03.4: User stays logged in across refreshes/reopening
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
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
end
