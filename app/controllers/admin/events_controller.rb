class Admin::EventsController < ApplicationController
  before_action :require_admin

  def index
    @events = Event.order(event_date_time: :asc)
  end

  private

  def require_admin
    redirect_to root_path, alert: 'Access denied.' unless current_member&.is_admin?
  end
end
