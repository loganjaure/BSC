# frozen_string_literal: true

class Admin::CategoriesController < ApplicationController
  before_action :require_admin
  before_action :set_category, only: %i[edit update destroy]

  def index
    @categories = Category.order(:category_name)
  end

  def new
    @category = Category.new
  end

  def create
    @category = Category.new(category_params)

    if @category.save
      redirect_to admin_events_path(anchor: 'categories'), notice: 'Category created successfully.'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_to admin_events_path, notice: 'Category updated successfully.'
    else
      render :edit, status: :unprocessable_entity
    end
  end



  def destroy
    replacement_category = nil

    # A replacement is required if events belong to this category.
    if @category.events.exists?
      replacement_category = Category.find_by(
        id: params[:replacement_category_id]
      )

      if replacement_category.nil? || replacement_category == @category
        redirect_to admin_categories_path,
                    alert: 'Please select a valid replacement category.'
        return
      end
    end

    Category.transaction do
      # Reassign existing events without deleting them.
      if replacement_category
        @category.events.find_each do |event|
          event.update!(category: replacement_category)
        end
      end

      # Remove semester associations.
      @category.semester_requirements.destroy_all

      # Finally delete the category.
      @category.destroy!
    end

    redirect_to admin_events_path(anchor: 'categories'),
                notice: 'Category deleted successfully. Events have been reassigned.'

  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotDestroyed => e
    redirect_to admin_categories_path,
                alert: "Could not delete category: #{e.message}"
  end


  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:category_name)
  end

  def require_admin
    redirect_to root_path, alert: 'Access denied.' unless current_member&.is_admin?
  end
end
