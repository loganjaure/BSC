class AdminController < ApplicationController
  before_action :require_admin
  before_action :set_member, only: [ :show_member, :promote_member ]

  def index
    @members = Member.order(:name)
  end

  def show_member
    @events = @member.events.order(event_date_time: :desc)
  end

  def promote_member
    if @member.is_admin?
      redirect_to admin_member_path(@member),
                  notice: "#{@member.name} is already an admin."
      return
    end

    if @member.update(is_admin: true)
      redirect_to admin_member_path(@member),
                  notice: "#{@member.name} is now an admin."
    else
      redirect_to admin_member_path(@member),
                  alert: "The member could not be made an admin."
    end
  end

  private

  def set_member
    @member = Member.find(params[:id])
  end

  def require_admin
    redirect_to root_path, alert: 'Access denied.' unless current_member&.is_admin?
  end
end