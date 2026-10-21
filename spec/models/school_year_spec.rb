# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SchoolYear, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let!(:fall) { Semester.create!(term_name: 'Fall 2026') }
  let!(:spring) { Semester.create!(term_name: 'Spring 2027') }
  let!(:meetings) { Category.create!(category_name: 'General Meeting') }
  let!(:service) { Category.create!(category_name: 'Service') }
  let(:member) { create_member('member@tamu.edu', 'Member') }
  let(:year) { described_class.new(2026) }

  def create_member(email, name, **attrs)
    user = User.create!(email: email)
    Member.create!(user: user, name: name, tamu_email: email, uin: 100_000_000 + User.count, class_year: 2027, **attrs)
  end

  def earn(who, points, at:, category: meetings, semester: fall)
    event = Event.create!(event_name: "Event #{Event.count + 1}", description: 'Test event', event_date_time: at,
                          category: category, semester: semester, point_value: points)
    Attendance.create!(member: who, event: event, check_in_time: at, status: 'present')
  end

  def central(*args)
    Time.zone.local(*args)
  end

  describe 'school year boundaries' do
    # AC-25.02: points are recorded by school year (Aug 1 - Jul 31)
    it 'puts Jul 31 in the earlier school year and starts the new one on Aug 1' do
      expect(described_class.containing(central(2026, 7, 31, 23, 59, 59)).label).to eq('2025-2026')
      expect(described_class.containing(central(2026, 8, 1, 0, 0, 0)).label).to eq('2026-2027')
    end

    it 'covers Aug 1 through Jul 31 in the app time zone' do
      expect(year.range).to cover(central(2026, 8, 1))
      expect(year.range).to cover(central(2027, 7, 31, 23, 59, 59))
      expect(year.range).not_to cover(central(2027, 8, 1))
    end

    it 'parses labels like "2026-2027" and rejects anything else' do
      expect(described_class.parse('2026-2027')).to eq(year)
      expect(described_class.parse('2026-2028')).to be_nil
      expect(described_class.parse('junk')).to be_nil
      expect(described_class.parse(nil)).to be_nil
    end

    it 'knows the current school year' do
      travel_to(central(2027, 3, 1)) { expect(described_class.current).to eq(year) }
    end
  end

  # AC-25.02: one uncategorized yearly total computed from existing attendance and event data
  describe '#total_points_for' do
    it 'adds Fall and Spring points into one total without resetting between semesters' do
      earn(member, 2, at: central(2026, 9, 10), semester: fall)
      earn(member, 3, at: central(2027, 2, 10), semester: spring)

      expect(year.total_points_for(member)).to eq(5)
    end

    it 'excludes points from a different school year' do
      earn(member, 2, at: central(2026, 9, 10))
      earn(member, 10, at: central(2026, 3, 10))
      earn(member, 7, at: central(2027, 9, 10))

      expect(year.total_points_for(member)).to eq(2)
    end

    it 'counts a Jul 31 event in the earlier year and an Aug 1 event in the new year' do
      earn(member, 4, at: central(2026, 7, 31, 18, 0))
      earn(member, 6, at: central(2026, 8, 1, 9, 0))

      expect(described_class.new(2025).total_points_for(member)).to eq(4)
      expect(year.total_points_for(member)).to eq(6)
    end

    it 'equals the sum of the category points for that year' do
      earn(member, 2, at: central(2026, 9, 10), category: meetings)
      earn(member, 1.5, at: central(2026, 11, 10), category: service)
      earn(member, 3, at: central(2027, 4, 10), category: service, semester: spring)

      by_category = year.points_by_member_and_category.select { |(member_id, _), _| member_id == member.id }
      expect(by_category).to eq({ [ member.id, meetings.id ] => 2, [ member.id, service.id ] => 4.5 })
      expect(year.total_points_for(member)).to eq(by_category.values.sum)
    end

    it 'is 0 for a member with no points that year' do
      earn(member, 5, at: central(2025, 10, 1))

      expect(year.total_points_for(member)).to eq(0)
    end

    it 'leaves out the undated admin points adjustment' do
      adjusted = create_member('adjusted@tamu.edu', 'Adjusted', points_adjustment: 50)
      earn(adjusted, 2, at: central(2026, 9, 10))

      expect(year.total_points_for(adjusted)).to eq(2)
    end

    it 'does not include other members\' points' do
      other = create_member('other@tamu.edu', 'Other')
      earn(other, 9, at: central(2026, 9, 10))

      expect(year.total_points_for(member)).to eq(0)
    end
  end
end
