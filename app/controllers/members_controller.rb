class MembersController < ApplicationController
  before_action :set_member, only: [ :show, :edit, :update ]

  # GET /members/:id
  def show
  end

  # GET /members/:id/edit
  def edit
  end

  # PATCH/PUT /members/:id
  def update
    if @member.update(member_params)
      redirect_to @member, notice: 'Profile updated successfully!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_member
    @member = current_member
    raise ActiveRecord::RecordNotFound unless @member && @member.id.to_s == params[:id] && !@member.archived?
  end

  def member_params
    params.require(:member).permit(:name, :uin, :class_year)
  end
end
