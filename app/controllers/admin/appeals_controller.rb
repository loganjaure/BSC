# frozen_string_literal: true

class Admin::AppealsController < ApplicationController
  before_action :require_admin
  before_action :set_appeal, only: %i[show update]

  def index
    @appeals = Appeal.includes(:submitting_member, :event).order(created_at: :desc, id: :desc)
  end

  def show; end

  def update
    Admin::AppealReview.new(actor: current_member, appeal: @appeal).decide!(params[:decision])
    redirect_to admin_appeal_path(@appeal), notice: "Appeal #{@appeal.status.capitalize}.", status: :see_other
  rescue Admin::AppealReview::Error, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => error
    redirect_to admin_appeal_path(@appeal), alert: error.message, status: :see_other
  end

  private

  def set_appeal
    @appeal = Appeal.includes(:submitting_member, :event).find(params[:id])
  end

  def require_admin
    redirect_to root_path, alert: 'Access denied.' unless current_member&.is_admin?
  end
end
