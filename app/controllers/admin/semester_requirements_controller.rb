# frozen_string_literal: true

class Admin::SemesterRequirementsController < ApplicationController
  before_action :require_admin

  def index
    @semesters = Semester.order(id: :desc)
    @categories = Category.order(:category_name)
    @semester = Semester.find_by(id: params[:semester_id]) ||
                @semesters.first

    @requirements = if @semester
                      @semester.semester_requirements.index_by(&:category_id)
                    else
                      {}
                    end
  end

  def update
    @semester = Semester.find(params[:semester_id])

    ActiveRecord::Base.transaction do
      (params[:requirements] || {}).each do |category_id, attributes|
        category = Category.find(category_id)
        value = attributes[:required_count].to_s.strip

        requirement = @semester.semester_requirements.find_by(
          category_id: category.id
        )

        if value.empty?
          requirement&.destroy!
        else
          requirement ||= @semester.semester_requirements.build(
            category: category
          )
          requirement.required_count = value
          requirement.save!
        end
      end
    end

    redirect_to admin_semester_requirements_path(semester_id: @semester.id),
                notice: 'Semester category requirements saved.'
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotDestroyed => e
    redirect_to admin_semester_requirements_path(
      semester_id: @semester_id
    ), alert: e.message
  rescue ActiveRecord::RecordNotFound
    redirect_to admin_semester_requirements_path,
                alert: 'The selected semester or category was not found.'
  end

  private

  def require_admin
    redirect_to root_path, alert: 'Access denied.' unless current_member&.is_admin?
  end
end
