module EventsHelper
  # "Thursday 9/24/2026, 6:00 PM"
  def event_datetime(event)
    return 'Date TBD' if event.event_date_time.blank?

    event.event_date_time.in_time_zone.strftime('%A %-m/%-d/%Y, %-l:%M %p')
  end

  # 5.0 -> "5", 0.5 -> "0.5"
  def format_points(value)
    number_with_precision(value || 0, precision: 2, strip_insignificant_zeros: true)
  end

  def event_points(event)
    pluralize(format_points(event.point_value), 'point')
  end

  # AC-05.5: blank profile fields show "Not Provided"
  def display_or_not_provided(value)
    value.present? ? value : content_tag(:span, 'Not Provided', class: 'bsc-muted')
  end
end
