class CheckInsController < ApplicationController
  before_action :require_login
  before_action :require_member
  before_action :set_event

  # AC-04.1: check-in page only opens for active events
  # AC-04.2: @attendance tells the view whether the member already checked in
  def show
    return redirect_to(root_path, alert: "#{@event.event_name} isn't open for check-in yet.") unless @event.active?

    @attendance = current_member.attendances.find_by(event: @event)
  end
  # AC-04.1: records the member's attendance; points come from Member#total_points
  # AC-04.2: find_or_create_by! means a second check-in never creates a duplicate
  def create
    # Never trust the button: re-check on the server
    return render json: { error: "This event isn't open for check-in yet." }, status: :unprocessable_entity unless @event.active?

    attendance = current_member.attendances.find_or_create_by!(event: @event) do |a|
      a.check_in_time = Time.current
      a.status = 'present'
    end

    render json: { checked_in: true, check_in_time: attendance.check_in_time }
  rescue ActiveRecord::RecordNotUnique
    # Double-tap race: the other request already saved it
    render json: { checked_in: true }
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def require_member
    return if current_member

    if request.format.json?
      render json: { error: 'Set up your member profile first.' }, status: :forbidden
    else
      redirect_to new_member_path, alert: 'Set up your member profile before checking in.'
    end
  end
end
