# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CategoryProgress, type: :model do
  let!(:semester) { Semester.create!(term_name: 'Fall 2026') }
  let!(:meetings) { Category.create!(category_name: 'General Meeting') }
  let!(:service) { Category.create!(category_name: 'Service') }
  let(:member) { build_member('member@tamu.edu', '123456789') }

  def build_member(email, uin)
    user = User.create!(email: email)
    Member.create!(user: user, name: 'Test Member', tamu_email: email, uin: uin, class_year: 2027)
  end

  def create_event(category:, points:, term: semester)
    Event.create!(category: category, semester: term, event_name: "#{category.category_name} #{points}", description: 'Test event description',
                  event_date_time: 1.day.ago, point_value: points)
  end

  def check_in(who, event)
    Attendance.create!(member: who, event: event, check_in_time: Time.current, status: 'present')
  end

  def require_points(category, count)
    SemesterRequirement.create!(semester: semester, category: category, required_count: count)
  end

  def row_for(category)
    CategoryProgress.for(member, semester).find { |row| row.category == category }
  end

  # AC-16:01: earned points per category come from the member's check-ins
  describe 'earned points' do
    it 'is 0 when the member has not checked in to anything' do
      require_points(meetings, 3)

      expect(row_for(meetings).earned).to eq(0)
    end

    it 'increases by the event point value after a check-in' do
      require_points(meetings, 3)
      check_in(member, create_event(category: meetings, points: 1))
      check_in(member, create_event(category: meetings, points: 1.5))

      expect(row_for(meetings).earned).to eq(2.5)
    end

    it 'keeps each category separate' do
      check_in(member, create_event(category: meetings, points: 2))
      check_in(member, create_event(category: service, points: 5))

      expect(row_for(meetings).earned).to eq(2)
      expect(row_for(service).earned).to eq(5)
    end

    it 'does not count points earned by other members' do
      other = build_member('other@tamu.edu', '987654321')
      check_in(other, create_event(category: meetings, points: 4))

      expect(row_for(meetings).earned).to eq(0)
    end

    it 'does not count events from a different semester' do
      old_term = Semester.create!(term_name: 'Spring 2026')
      check_in(member, create_event(category: meetings, points: 4, term: old_term))

      expect(row_for(meetings).earned).to eq(0)
    end
  end

  describe 'requirement status' do
    it 'is not satisfied when under the requirement' do
      require_points(meetings, 3)
      check_in(member, create_event(category: meetings, points: 2))

      row = row_for(meetings)
      expect(row.required).to eq(3)
      expect(row).not_to be_satisfied
    end

    it 'is satisfied when exactly at the requirement' do
      require_points(meetings, 3)
      check_in(member, create_event(category: meetings, points: 3))

      expect(row_for(meetings)).to be_satisfied
    end

    it 'is satisfied and keeps the real total when over the requirement' do
      require_points(meetings, 3)
      check_in(member, create_event(category: meetings, points: 5))

      row = row_for(meetings)
      expect(row).to be_satisfied
      expect(row.earned).to eq(5)
    end

    it 'treats a requirement of 0 as satisfied, even with 0 points' do
      require_points(meetings, 0)

      expect(row_for(meetings)).to be_satisfied
    end

    it 'marks categories without a requirement row as having no requirement' do
      check_in(member, create_event(category: service, points: 2))

      row = row_for(service)
      expect(row.requirement?).to be(false)
      expect(row).not_to be_satisfied
      expect(row.earned).to eq(2)
    end

    it 'ignores requirements from other semesters' do
      old_term = Semester.create!(term_name: 'Spring 2026')
      SemesterRequirement.create!(semester: old_term, category: meetings, required_count: 3)

      expect(row_for(meetings).requirement?).to be(false)
    end
  end

  describe 'rows' do
    it 'lists every category in name order' do
      expect(CategoryProgress.for(member, semester).map(&:category)).to eq([ meetings, service ])
    end

    it 'is empty when there is no current semester' do
      expect(CategoryProgress.for(member, nil)).to eq([])
    end

    it 'is empty when there is no member' do
      expect(CategoryProgress.for(nil, semester)).to eq([])
    end


    it 'uses a fixed number of queries no matter how many categories exist' do
      5.times { |i| Category.create!(category_name: "Extra #{i}") }
      member # create before counting

      queries = 0
      counter = ->(*, payload) { queries += 1 unless payload[:name] == 'SCHEMA' }
      ActiveSupport::Notifications.subscribed(counter, 'sql.active_record') do
        CategoryProgress.for(member, semester).each { |row| [ row.category.category_name, row.earned, row.required ] }
      end

      expect(queries).to eq(3)
    end
  end
end
