class AdminController < ApplicationController
  before_action :require_admin

  def index
    @members = Member.order(:name)
  end

  private

  def require_admin
    unless current_member&.is_admin?
      redirect_to root_path, alert: "Access denied."
    end
  end
end
