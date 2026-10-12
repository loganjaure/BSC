# frozen_string_literal: true

class Admin::SemestersController < ApplicationController
  before_action :require_admin

  def create
    @semester = Semester.new(semester_params)

    if @semester.save
      redirect_to admin_events_path,
                  notice: "Semester created successfully."
    else
      redirect_to admin_events_path,
                  alert: @semester.errors.full_messages.to_sentence
    end
  end

  private

  def semester_params
    params.require(:semester).permit(:term_name)
  end

  def require_admin
    redirect_to root_path, alert: "Access denied." unless current_member&.is_admin?
  end
end
