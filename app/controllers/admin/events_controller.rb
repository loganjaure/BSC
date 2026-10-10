# app/controllers/admin/events_controller.rb
class Admin::EventsController < ApplicationController
  before_action :require_admin

  def index
    @events = Event.order(event_date_time: :asc)
  end

  def new
    # AC-13.01: Default point value to 1
    @event = Event.new(point_value: 1)
  end

  def create
    @event = Event.new(event_params)

    if @event.save
      # AC-13.02: Success confirmation message
      redirect_to admin_events_path, notice: 'Event successfully created!'
    else
      # AC-13.03: Block save and display errors
      render :new, status: :unprocessable_entity
    end
  end

  private

  def event_params
    params.require(:event).permit(:event_name, :event_date_time, :category_id, :semester_id, :description, :point_value)
  end

  def require_admin
    redirect_to root_path, alert: 'Access denied.' unless current_member&.is_admin?
  end
end
