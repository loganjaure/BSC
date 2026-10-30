# frozen_string_literal: true

require 'rails_helper'
require 'csv'

RSpec.describe 'Admin points export', type: :request do
  include ActiveSupport::Testing::TimeHelpers

  let!(:fall) { Semester.create!(term_name: 'Fall 2026') }
  let!(:spring) { Semester.create!(term_name: 'Spring 2027') }
  let!(:meetings) { Category.create!(category_name: 'General Meeting') }
  let!(:service) { Category.create!(category_name: 'Service') }

  let!(:admin) { create_member('admin@tamu.edu', 'Alice Admin', 100_000_001, is_admin: true) }
  let!(:bob) { create_member('bob@tamu.edu', 'Bob Earner', 100_000_002, points_adjustment: 50) }
  let!(:carol) { create_member('carol@tamu.edu', 'Carol Zero', 100_000_003) }
  let!(:dave) { create_member('dave@tamu.edu', 'Dave Archived', 100_000_004) }
  let!(:erin) { create_member('erin@tamu.edu', 'Erin Archived', 100_000_005, archived_at: 1.day.ago) }

  before do
    travel_to Time.zone.local(2026, 10, 15, 12, 0)

    earn(bob, 2, at: Time.zone.local(2026, 9, 10), category: meetings, semester: fall)
    earn(bob, 3, at: Time.zone.local(2027, 2, 10), category: service, semester: spring)
    earn(bob, 10, at: Time.zone.local(2026, 3, 10), category: meetings, semester: fall)
    earn(dave, 1, at: Time.zone.local(2026, 9, 12), category: service, semester: fall)
    # Dave earned points before being archived; archived members can't check in afterwards
    dave.update!(archived_at: 1.day.ago)
  end

  after do
    travel_back
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  def create_member(email, name, uin, **attrs)
    user = User.create!(email: email)
    Member.create!(user: user, name: name, tamu_email: email, uin: uin, class_year: 2027, **attrs)
  end

  def earn(who, points, at:, category:, semester:)
    event = Event.create!(event_name: "Event #{Event.count + 1}", description: 'Test event', event_date_time: at,
                          category: category, semester: semester, point_value: points)
    Attendance.create!(member: who, event: event, check_in_time: at, status: 'present')
  end

  def sign_in(member)
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google_oauth2', uid: "uid-#{member.id}", info: { email: member.tamu_email, name: member.name }
    )
    get '/auth/google_oauth2/callback'
  end

  def rows
    CSV.parse(response.body)
  end

  def row_for(name)
    rows.select { |row| row.first == name }
  end

  describe 'access' do
    # AC-25.01: the export is only available from the admin side
    it 'redirects a logged-out visitor to sign in' do
      get admin_export_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('Please sign in with your TAMU email to continue.')
    end

    it 'blocks a signed-in member who is not an admin' do
      sign_in(carol)
      get admin_export_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('Access denied.')
    end

    it 'shows the export form with school years on the admin dashboard' do
      sign_in(admin)
      get admin_path

      expect(response.body).to include('Export CSV')
      expect(response.body).to include(%(<option selected="selected" value="2026-2027">2026-2027</option>))
      expect(response.body).to include('2025-2026')
    end
  end

  # AC-25.01: an admin downloads a .csv with all member and point information
  describe 'as an admin' do
    before { sign_in(admin) }

    it 'downloads a .csv named for the school year' do
      get admin_export_path, params: { year: '2026-2027' }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/csv')
      expect(response.headers['Content-Disposition']).to include('attachment')
      expect(response.headers['Content-Disposition']).to include('filename="bsc_points_2026-2027.csv"')
    end

    it 'starts with the school year, then a blank line, then the header row' do
      get admin_export_path, params: { year: '2026-2027' }

      lines = response.body.lines.map(&:chomp)
      expect(lines[0]).to eq('BSC Member Points - School Year 2026-2027')
      expect(lines[1]).to eq('')
      expect(rows[2]).to eq([ 'Name', 'Email', 'UIN', 'Total Points', 'General Meeting', 'Service' ])
    end

    # AC-25.02: totals and category columns only count the selected school year
    it 'lists each member once with their email, UIN, yearly total, and per-category points' do
      get admin_export_path, params: { year: '2026-2027' }

      expect(rows.drop(3).map(&:first)).to eq([ 'Alice Admin', 'Bob Earner', 'Carol Zero', 'Dave Archived' ])
      expect(row_for('Bob Earner')).to eq([ [ 'Bob Earner', 'bob@tamu.edu', '="100000002"', '5', '2', '3' ] ])
    end

    it 'includes members with zero points as 0s' do
      get admin_export_path, params: { year: '2026-2027' }

      expect(row_for('Carol Zero')).to eq([ [ 'Carol Zero', 'carol@tamu.edu', '="100000003"', '0', '0', '0' ] ])
      expect(row_for('Alice Admin')).to eq([ [ 'Alice Admin', 'admin@tamu.edu', '="100000001"', '0', '0', '0' ] ])
    end

    it 'includes archived members only if they earned points that year' do
      get admin_export_path, params: { year: '2026-2027' }

      expect(row_for('Dave Archived')).to eq([ [ 'Dave Archived', 'dave@tamu.edu', '="100000004"', '1', '0', '1' ] ])
      expect(row_for('Erin Archived')).to be_empty
    end

    # AC-25.02: selecting another school year exports only that year's points
    it 'exports only the selected school year\'s data' do
      get admin_export_path, params: { year: '2025-2026' }

      expect(response.headers['Content-Disposition']).to include('bsc_points_2025-2026.csv')
      expect(response.body.lines.first.chomp).to eq('BSC Member Points - School Year 2025-2026')
      expect(row_for('Bob Earner')).to eq([ [ 'Bob Earner', 'bob@tamu.edu', '="100000002"', '10', '10', '0' ] ])
      expect(row_for('Dave Archived')).to be_empty
    end

    it 'defaults to the current school year when none is selected' do
      get admin_export_path

      expect(response.headers['Content-Disposition']).to include('bsc_points_2026-2027.csv')
      expect(row_for('Bob Earner').first[3]).to eq('5')
    end

    # AC-25.01: UINs export as full whole numbers, never scientific notation or decimals
    it 'writes each UIN so spreadsheets keep all 9 digits' do
      get admin_export_path

      uins = rows.drop(3).map { |row| row[2] }
      expect(uins).to all(match(/\A="\d{9}"\z/))
      expect(response.body).not_to match(/\d\.\d+E\+\d+/i)
      expect(response.body).to include('"=""100000002"""')
    end

    it 'neutralizes cells that could run as spreadsheet formulas' do
      carol.update!(name: '=HYPERLINK("x")')
      get admin_export_path

      expect(rows.map(&:first)).to include(%('=HYPERLINK("x")))
    end
  end
end
