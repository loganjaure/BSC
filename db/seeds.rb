# frozen_string_literal: true

admin_accounts = [
  {
    name: "Ruth Jasadiredja",
    email: "ruth_jasadiredja@tamu.edu"
  },
  {
    name: "Logan Jaure",
    email: "loganjaure@tamu.edu"
  }
].freeze

admin_accounts.each do |account|
  email = account[:email].downcase

  user = User.find_or_initialize_by(email: email)
  user.name = account[:name] if user.name.blank?
  user.full_name = account[:name] if user.full_name.blank?
  user.save!

  member = Member.find_or_initialize_by(tamu_email: email)
  member.name = account[:name] if member.name.blank?
  member.user = user
  member.is_admin = true

  if member.new_record?
    member.save!
  else
    # Existing members may not have completed their UIN and class year yet.
    member.save!(validate: false)
  end

  puts "Seeded administrator: #{email}"
end

central = ActiveSupport::TimeZone["Central Time (US & Canada)"]
tomorrow_11am = central.now.tomorrow.change(hour: 11)

category = Category.find_or_create_by!(category_name: "General Meeting")
semester = Semester.find_or_create_by!(term_name: "Fall 2026")

SemesterRequirement.find_or_create_by!(semester: semester, category: category) do |requirement|
  requirement.required_count = 3
end

Event.find_or_create_by!(
  event_name: "BSC Test Event",
  event_date_time: tomorrow_11am
) do |event|
  event.point_value = 1
  event.category = category
  event.semester = semester
end

puts "Seeded: BSC Test Event on #{tomorrow_11am.strftime('%A %-m/%-d/%Y at %-l:%M %p %Z')}"
