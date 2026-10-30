class HomeController < ApplicationController
  skip_before_action :require_login

  def index
    return unless logged_in?

    # AC-05.6: list events; active ones are clickable, future ones greyed out
    events = Event.order(event_date_time: :asc).to_a

    @upcoming_events = events.select do |event|
      event.event_date_time.present? && event.event_date_time >= Time.current
    end

    @past_events = events.select do |event|
      event.event_date_time.nil? || event.event_date_time < Time.current
    end.reverse

    @checked_in_ids = current_member ? current_member.attendances.pluck(:event_id) : []

    # AC-05.1 / AC-05.3: current points (0 for a new member), now shown per category
    # AC-16:01: points earned per category for the current semester (calculated in CategoryProgress)
    @current_semester = Semester.current
    @category_progress = CategoryProgress.for(current_member, @current_semester)
  end
end

