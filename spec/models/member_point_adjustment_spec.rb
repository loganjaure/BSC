# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Member point adjustments', type: :model do
  let!(:user) { User.create!(email: 'point-adjustment@tamu.edu') }
  let!(:member) do
    Member.create!(user: user, name: 'Point Member', tamu_email: user.email, uin: 123987456, class_year: 2027)
  end
  let(:category) { Category.create!(category_name: 'Point test') }
  let(:semester) { Semester.create!(term_name: 'Fall 2026') }
  let(:event) do
    Event.create!(event_name: 'Point event', description: 'Adjustment regression event',
                  event_date_time: Time.current, point_value: 2.5, category: category, semester: semester)
  end

  it 'defaults existing and new members to no adjustment' do
    expect(member.points_adjustment).to eq(0)
    expect(member.total_points).to eq(0)
  end

  it 'allows a downward correction without modifying an event or attendance' do
    attendance = Attendance.create!(member: member, event: event)
    member.update!(total_points: '1.25')
    expect(member.reload.total_points).to eq(1.25)
    expect(member.points_adjustment).to eq(-1.25)
    expect(attendance.reload.event_id).to eq(event.id)
    expect(event.reload.point_value).to eq(2.5)
  end

  it 'does not repeat an adjustment when saving an unrelated profile field' do
    member.update!(total_points: '3.75')
    member.update!(name: 'Renamed')
    Attendance.create!(member: member, event: event)
    expect(member.reload.total_points).to eq(6.25)
  end

  it 'retains the total when a correction is submitted twice' do
    member.update!(total_points: '8.5')
    member.update!(total_points: '8.5')
    expect(member.reload.total_points).to eq(8.5)
  end

  it 'allows a check-in immediately after a correction on the same member instance' do
    member.update!(total_points: '5')
    Attendance.create!(member: member, event: event)
    expect(member.reload.total_points).to eq(7.5)
  end

  it 'rejects a check-in for an archived member and retains prior attendance' do
    Attendance.create!(member: member, event: event)
    member.update!(archived_at: Time.current)
    another_event = event.dup
    another_event.save!
    attendance = Attendance.new(member: member, event: another_event)
    expect(attendance.save).to be(false)
    expect(attendance.errors[:member]).to include('has been archived')
    expect(member.attendances.count).to eq(1)
  end
end
