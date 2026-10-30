
# frozen_string_literal: true

require "rails_helper"

RSpec.describe HomeController, type: :controller do
    include ActiveSupport::Testing::TimeHelpers
  let!(:user) do
    User.create!(
      email: "dashboard_test@tamu.edu",
      full_name: "Dashboard Test"
    )
  end

  let!(:member) do
    Member.create!(
      user: user,
      name: "Dashboard Test",
      tamu_email: "dashboard_test@tamu.edu",
      uin: 123456789,
      class_year: 2027
    )
  end

  let!(:category) do
    Category.create!(category_name: "General")
  end

  let!(:semester) do
    Semester.create!(term_name: "Fall 2026")
  end

  before do
    session[:user_id] = user.id
    allow(CategoryProgress).to receive(:for).and_return([])
  end

  describe "GET #index" do
    around do |example|
      travel_to(Time.zone.parse("2026-10-30 12:00:00")) do
        example.run
      end
    end

    def create_event(name, date_time)
      Event.create!(
        event_name: name,
        event_date_time: date_time,
        description: "Test event",
        point_value: 1,
        category: category,
        semester: semester
      )
    end

    it "places future events in upcoming events" do
      upcoming = create_event("Upcoming Event", 1.day.from_now)

      get :index

      expect(assigns(:upcoming_events)).to include(upcoming)
      expect(assigns(:past_events)).not_to include(upcoming)
    end

    it "places past events in past events" do
      past = create_event("Past Event", 1.day.ago)

      get :index

      expect(assigns(:past_events)).to include(past)
      expect(assigns(:upcoming_events)).not_to include(past)
    end

    it "places an event happening now in upcoming events" do
      event = create_event("Current Event", Time.current)

      get :index

      expect(assigns(:upcoming_events)).to include(event)
    end

    it "places multiple events in their correct sections" do
      upcoming = create_event("Upcoming Event", 1.day.from_now)
      past = create_event("Past Event", 1.day.ago)

      get :index

      expect(assigns(:upcoming_events)).to include(upcoming)
      expect(assigns(:upcoming_events)).not_to include(past)

      expect(assigns(:past_events)).to include(past)
      expect(assigns(:past_events)).not_to include(upcoming)
    end
  end
end
