# frozen_string_literal: true

require 'csv'

# A BSC school year runs Aug 1 through Jul 31 (e.g. "2026-2027") in the app time zone.
# Yearly points are calculated from attendances and event dates; nothing new is stored.
class SchoolYear
  START_MONTH = 8
  # Cells starting with these could run as formulas when the CSV is opened in Excel
  FORMULA_PREFIXES = [ '=', '+', '-', '@', "\t", "\r" ].freeze

  attr_reader :start_year

  def self.current
    containing(Time.current)
  end

  def self.containing(time)
    time = time.in_time_zone
    new(time.month >= START_MONTH ? time.year : time.year - 1)
  end

  # "2026-2027" -> SchoolYear starting 2026; anything else -> nil
  def self.parse(label)
    match = label.to_s.match(/\A(\d{4})-(\d{4})\z/)
    new(match[1]) if match && match[2].to_i == match[1].to_i + 1
  end

  # Every school year that has events, plus the current one, newest first
  def self.available
    first_event, last_event = Event.pick(Arel.sql('MIN(event_date_time), MAX(event_date_time)'))
    years = [ current.start_year ]
    years += [ containing(first_event).start_year, containing(last_event).start_year ] if first_event
    years.max.downto(years.min).map { |year| new(year) }
  end

  def initialize(start_year)
    @start_year = Integer(start_year)
  end

  def label
    "#{start_year}-#{start_year + 1}"
  end

  def ==(other)
    other.is_a?(SchoolYear) && other.start_year == start_year
  end
  alias eql? ==

  delegate :hash, to: :start_year

  # AC-25.02: a point belongs to the school year containing its event's date
  def range
    starts_at = Time.zone.local(start_year, START_MONTH, 1)
    starts_at...starts_at.next_year
  end

  # AC-25.02: one total across Fall and Spring (no reset between semesters).
  # Admin points_adjustment is left out because it has no date or category.
  def total_points_for(member)
    member.events.where(event_date_time: range).sum(:point_value)
  end

  # AC-25.02: this school year's points grouped by member and category,
  # as { [member_id, category_id] => points }, in one query
  def points_by_member_and_category
    Attendance.joins(:event)
              .where(events: { event_date_time: range })
              .group(:member_id, 'events.category_id')
              .sum('events.point_value')
  end

  # AC-25.01: every member's name, email, UIN, total, and per-category points for this year
  def to_csv
    categories = Category.order(:category_name).to_a
    points = points_by_member_and_category

    CSV.generate do |csv|
      csv << [ "BSC Member Points - School Year #{label}" ]
      csv << []
      csv << [ 'Name', 'Email', 'UIN', 'Total Points', *categories.map { |category| safe_cell(category.category_name) } ]
      export_members(points).each do |member|
        by_category = categories.map { |category| points.fetch([ member.id, category.id ], 0) }
        csv << [ safe_cell(member.name), safe_cell(member.tamu_email), uin_cell(member.uin),
                 format_points(by_category.sum), *by_category.map { |value| format_points(value) } ]
      end
    end
  end

  private

  # Active members (0s if no points), plus archived members who earned points this year
  def export_members(points)
    earner_ids = points.select { |_key, value| value.positive? }.keys.map(&:first).uniq
    Member.active.or(Member.where(id: earner_ids)).order(:name, :id)
  end

  def safe_cell(value)
    text = value.to_s
    text.start_with?(*FORMULA_PREFIXES) ? "'#{text}" : text
  end

  # AC-25.01: Excel shows long numbers in scientific notation (1.23E+08) and may round them;
  # writing ="123456789" makes it keep the UIN as the full whole number. Integer() allows digits only.
  def uin_cell(uin)
    uin.nil? ? '' : %(="#{Integer(uin)}")
  end

  # 3.0 -> 3, 2.5 -> 2.5
  def format_points(value)
    value = value.to_d
    value.frac.zero? ? value.to_i : value.to_s('F')
  end
end
