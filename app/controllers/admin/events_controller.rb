# frozen_string_literal: true

class Admin::EventsController < ApplicationController
  before_action :require_admin
  before_action :set_event, only: %i[edit update]
  before_action :load_form_options, only: %i[new create edit update]

  def index
    @upcoming_events = Event.includes(:category, :semester)
                            .where("event_date_time >= ?", Time.current)
                            .order(event_date_time: :asc)

    @past_events = Event.includes(:category, :semester)
                        .where("event_date_time < ?", Time.current)
                        .order(event_date_time: :desc)

    @categories = Category.order(:category_name)
    @category = Category.new
    @semesters = Semester.order(id: :desc)
    @current_semester = Semester.current
    @semester = Semester.new
  end


  def new
    @event = Event.new(point_value: 1)
  end

  def create
    @event = Event.new(event_params)

    if @event.save
      redirect_to admin_events_path, notice: 'Event successfully created!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @event.update(event_params)
      redirect_to admin_events_path, notice: 'Event successfully updated!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def load_form_options
    @categories = Category.order(:category_name)
    @semesters = Semester.order(id: :desc)
  end

  def event_params
    params.require(:event).permit(
      :event_name,
      :event_date_time,
      :category_id,
      :semester_id,
      :description,
      :point_value
    )
  end

  def require_admin
    redirect_to root_path, alert: 'Access denied.' unless current_member&.is_admin?
  end
end
