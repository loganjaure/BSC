# frozen_string_literal: true

class AppealsController < ApplicationController
  def index
    @appeals = current_member ? current_member.submitted_appeals.includes(:event).order(created_at: :desc, id: :desc) : Appeal.none
  end
end
