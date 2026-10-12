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
      redirect_to admin_events_path, notice: 'Category created successfully.'
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
        if @category.events.exists? || @category.semester_requirements.exists?
            redirect_to admin_categories_path,
                alert: 'Cannot delete a category used by events or semester requirements.'
        elsif @category.destroy
            redirect_to admin_events_path, notice: 'Category deleted successfully.'
        else
            redirect_to admin_categories_path,
                alert: @category.errors.full_messages.to_sentence
        end
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
