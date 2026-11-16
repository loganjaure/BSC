# app/controllers/appeals_controller.rb
# frozen_string_literal: true

class AppealsController < ApplicationController
  before_action :require_login

  def index
    @appeal = Appeal.new
    load_appeals_data
  end

  def create
    @appeal = current_member.submitted_appeals.build(appeal_params)

    if @appeal.save
      redirect_to appeals_path, notice: 'Your appeal has been submitted successfully.'
    else
      load_appeals_data
      render :index, status: :unprocessable_entity
    end
  end

  private

  def load_appeals_data
    @past_events = Event.where('event_date_time < ?', Time.current).order(event_date_time: :desc)
    @upcoming_events = Event.where('event_date_time >= ?', Time.current).order(event_date_time: :asc)
    @past_event_options = event_options(@past_events)
    @upcoming_event_options = event_options(@upcoming_events)

    # AC-11.04: Fetch the logged-in member's submitted appeals
    @appeals = current_member ? current_member.submitted_appeals.includes(:event).order(created_at: :desc, id: :desc) : Appeal.none
  end

  def event_options(events)
    events.map do |event|
      ["#{event.event_name} (#{event.event_date_time.strftime('%b %d, %Y')})", event.id]
    end
  end

  def appeal_params
    params.require(:appeal).permit(:event_id, :reason, :proof)
  end
end
