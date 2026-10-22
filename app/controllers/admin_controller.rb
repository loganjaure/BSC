# frozen_string_literal: true

class AdminController < ApplicationController
  before_action :require_admin
  before_action :set_member, only: %i[
    show_member edit_member update_member promote_member revoke_member
    delete_member destroy_member
  ]

  rescue_from Admin::MemberManagement::Error, with: :member_action_failed

  def index
    @show_archived = params[:archived] == '1'
    @members = (@show_archived ? Member.archived : Member.active).order(:name)
    # AC-25.01: school years offered by the export form
    @school_years = SchoolYear.available
  end

  # AC-25.01: admin-only .csv download of member points for the selected school year
  # (defaults to the current school year); access is guarded by require_admin above
  def export
    school_year = SchoolYear.parse(params[:year]) || SchoolYear.current
    send_data school_year.to_csv, filename: "bsc_points_#{school_year.label}.csv", type: 'text/csv'
  end

  def show_member
    @events = @member.events.order(event_date_time: :desc)
  end

  def edit_member; end

  def update_member
    if member_management.update(member_params)
      redirect_to admin_member_path(@member),
                  notice: 'Member information updated.', status: :see_other
    else
      render :edit_member, status: :unprocessable_content
    end
  end

  def promote_member
    changed = member_management.promote!
    message = changed ? "#{@member.name} is now an admin." : "#{@member.name} is already an admin."
    redirect_to admin_member_path(@member), notice: message, status: :see_other
  end

  def revoke_member
    changed = member_management.revoke!
    message = changed ? "#{@member.name} is no longer an admin." : "#{@member.name} is already a member."
    redirect_to admin_member_path(@member), notice: message, status: :see_other
  end

  def delete_member
    @deletion_blocker = member_management.deletion_blocker
  end

  def destroy_member
    unless params[:confirm_delete] == '1'
      redirect_to delete_admin_member_path(@member),
                  alert: 'Confirm deletion by checking the confirmation box.', status: :see_other
      return
    end

    member_management.archive!
    redirect_to admin_path, notice: 'Member removed from the roster. Records are retained and sign-in is disabled.', status: :see_other
  end

  private

  def member_management
    @member_management ||= Admin::MemberManagement.new(actor: current_member, member: @member)
  end

  def member_params
    params.require(:member).permit(:name, :uin, :class_year, :tamu_email, :total_points)
  end

  def member_action_failed(error)
    redirect_to admin_path, alert: error.message, status: :see_other
  end

  def set_member
    @member = Member.find(params[:id])
    return unless @member.archived? && action_name != 'show_member'

    redirect_to admin_member_path(@member), alert: 'This member has been archived.'
  end

  def require_admin
    redirect_to root_path, alert: 'Access denied.' unless current_member&.is_admin?
  end
end
