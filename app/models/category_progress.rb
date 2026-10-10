# frozen_string_literal: true

# Builds one row per category with a member's earned points vs. the points
# required for a semester, in a fixed number of queries (no per-category queries).
class CategoryProgress
  # AC-16:01: earned = sum of point values from this member's check-ins in the category
  Row = Struct.new(:category, :earned, :required, keyword_init: true) do
    # nil required means the category has no semester_requirement row this semester
    def requirement?
      !required.nil?
    end

    # A required value of 0 counts as satisfied; earned above required still counts
    def satisfied?
      requirement? && earned >= required
    end
  end

  def self.for(member, semester)
    return [] if member.nil? || semester.nil?

    earned = member.events.where(semester: semester).group(:category_id).sum(:point_value)
    # required_count is treated as POINTS required (compared against summed
    # events.point_value), not as a number of events attended.
    required = semester.semester_requirements.pluck(:category_id, :required_count).to_h

    Category.order(:category_name).map do |category|
      Row.new(category: category, earned: earned.fetch(category.id, 0), required: required[category.id])
    end
  end
end
