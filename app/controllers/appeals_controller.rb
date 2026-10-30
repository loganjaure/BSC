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
    # AC-11.01: Query only events that have already taken place
    @passed_events = Event.where('event_date_time < ?', Time.current).order(event_date_time: :desc)

    # AC-11.04: Fetch the logged-in member's submitted appeals
    @appeals = current_member ? current_member.submitted_appeals.includes(:event).order(created_at: :desc, id: :desc) : Appeal.none
  end

  def appeal_params
    params.require(:appeal).permit(:event_id, :reason)
  end
end
