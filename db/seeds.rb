# frozen_string_literal: true

admin_accounts = [
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

  member = user.member || Member.find_or_initialize_by(tamu_email: email)
  if member.archived?
    puts "Skipped archived administrator: #{email}"
    next
  end
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
