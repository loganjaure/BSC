# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Home page category progress', type: :request do
  let(:user) { User.create!(email: 'progress@tamu.edu') }
  let!(:member) { Member.create!(user: user, name: 'Progress Member', tamu_email: 'progress@tamu.edu', uin: '123456789', class_year: 2027) }

  after { OmniAuth.config.mock_auth[:google_oauth2] = nil }

  def sign_in
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google_oauth2', uid: '66666', info: { email: user.email, name: member.name }
    )
    get '/auth/google_oauth2/callback'
  end

  def earn(category, points, semester)
    event = Event.create!(category: category, semester: semester, event_name: "#{category.category_name} event", description: 'Sample event description',
                          event_date_time: 1.day.ago, point_value: points)
    Attendance.create!(member: member, event: event, check_in_time: Time.current, status: 'present')
  end

  def row(category)
    Nokogiri::HTML(response.body).at_css(%(li.bsc-progress[data-category-id="#{category.id}"]))
  end

  def number(category)
    row(category).at_css('.bsc-total__num').text.squish
  end

  def squish(node)
    node.text.squish
  end

  context 'with a current semester' do
    let!(:semester) { Semester.create!(term_name: 'Fall 2026') }
    let!(:meetings) { Category.create!(category_name: 'General Meeting') }
    let!(:service) { Category.create!(category_name: 'Service') }
    let!(:socials) { Category.create!(category_name: 'Socials') }
    let!(:workshops) { Category.create!(category_name: 'Workshops') }

    before do
      SemesterRequirement.create!(semester: semester, category: meetings, required_count: 3)
      SemesterRequirement.create!(semester: semester, category: service, required_count: 2)
      SemesterRequirement.create!(semester: semester, category: socials, required_count: 0)
      earn(meetings, 2, semester)
      earn(service, 4, semester)
      earn(workshops, 1, semester)

      sign_in
      get root_path
    end

    # AC-16:01: earned points per category appear on the home page
    it 'shows earned / required points for each category' do
      expect(number(meetings)).to eq('2 / 3')
      expect(number(service)).to eq('4 / 2')
      expect(number(socials)).to eq('0 / 0')
    end

    # AC-16:01: category points replace the old overall total
    it 'no longer shows the total points number' do
      expect(response.body).not_to include('Total points')
    end

    it 'shows the Satisfied indicator only on satisfied categories' do
      expect(row(meetings).at_css('[data-status="satisfied"]')).to be_nil
      expect(squish(row(meetings))).to include('In progress')

      expect(squish(row(service).at_css('[data-status="satisfied"]'))).to eq('✓ Satisfied')
      expect(row(socials).at_css('[data-status="satisfied"]')).not_to be_nil
    end

    it 'shows earned points with a No requirement label when no requirement is set' do
      expect(number(workshops)).to eq('1')
      expect(squish(row(workshops))).to include('No requirement')
      expect(row(workshops).at_css('[data-status="satisfied"]')).to be_nil
    end
  end

  context 'when a semester exists but no categories do' do
    it 'shows an empty-state message' do
      Semester.create!(term_name: 'Fall 2026')
      sign_in
      get root_path

      expect(response.body).to include('No categories have been set up yet.')
    end
  end

  context 'without any semester' do
    it 'shows a No active semester message instead of the progress list' do
      Category.create!(category_name: 'General Meeting')
      sign_in
      get root_path

      expect(response.body).to include('No active semester')
      expect(response.body).not_to include('bsc-progress-list')
    end
  end

  context 'when not signed in' do
    it 'shows the sign-in page without category progress' do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Sign in with Google')
      expect(response.body).not_to include('bsc-progress-list')
    end
  end
end
