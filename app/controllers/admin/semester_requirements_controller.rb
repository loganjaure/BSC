# frozen_string_literal: true

class Admin::SemesterRequirementsController < ApplicationController
  before_action :require_admin

  def index
    @semesters = Semester.order(:term_name)
    @semester = Semester.find_by(id: params[:semester_id]) || @semesters.first
    @categories = Category.order(:category_name)
    @requirements = @semester ? @semester.semester_requirements.index_by(&:category_id) : {}
  end

  def update
    @semester = Semester.find(params[:semester_id])
    requirements_params = params[:requirements] || {}

    requirements_params.each do |category_id, count|
      requirement = @semester.semester_requirements.find_or_initialize_by(category_id: category_id)

      if count.present?
        requirement.update(required_count: count)
      else
        requirement.destroy if requirement.persisted?
      end
    end

    redirect_to admin_semester_requirements_path(semester_id: @semester.id),
                notice: 'Category requirements saved successfully.'
  end

  private

  def require_admin
    redirect_to root_path, alert: 'Access denied.' unless current_member&.is_admin?
  end
end