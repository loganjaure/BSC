
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::EventsController, type: :controller do
    include ActiveSupport::Testing::TimeHelpers
  let!(:user) do
    User.create!(
      email: "admin_test@tamu.edu",
      full_name: "Admin Test"
    )
  end

  let!(:member) do
    Member.create!(
      user: user,
      name: "Admin Test",
      tamu_email: "admin_test@tamu.edu",
      uin: 123456789,
      class_year: 2027,
      is_admin: true
    )
  end

  let!(:category) do
    Category.create!(category_name: "Admin Test Category")
  end

  let!(:semester) do
    Semester.create!(term_name: "Admin Test Semester")
  end

  before do
    session[:user_id] = user.id
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
        description: "Admin test event",
        point_value: 1,
        category: category,
        semester: semester
      )
    end

    it "separates upcoming and past events" do
      upcoming = create_event("Upcoming Event", 1.day.from_now)
      past = create_event("Past Event", 1.day.ago)

      get :index

      expect(assigns(:upcoming_events)).to include(upcoming)
      expect(assigns(:upcoming_events)).not_to include(past)

      expect(assigns(:past_events)).to include(past)
      expect(assigns(:past_events)).not_to include(upcoming)
    end

    it "includes an event happening now in upcoming events" do
      event = create_event("Current Event", Time.current)

      get :index

      expect(assigns(:upcoming_events)).to include(event)
    end
  end

  describe "POST #create" do
    it "saves an event with a check-in code" do
      event_params = {
        event_name: "Coded Event",
        event_date_time: 1.day.from_now,
        description: "An event requiring a code",
        point_value: 2,
        category_id: category.id,
        semester_id: semester.id,
        check_in_code: "1234"
      }

      expect {
        post :create, params: { event: event_params }
      }.to change(Event, :count).by(1)

      expect(Event.last.check_in_code).to eq("1234")
      expect(response).to redirect_to(admin_events_path)
    end

    it "allows an event to be created without a check-in code" do
      event_params = {
        event_name: "No Code Event",
        event_date_time: 1.day.from_now,
        description: "An event without a code",
        point_value: 1,
        category_id: category.id,
        semester_id: semester.id,
        check_in_code: ""
      }

      expect {
        post :create, params: { event: event_params }
      }.to change(Event, :count).by(1)

      expect(Event.last.check_in_code).to be_blank
    end
  end

  describe "PATCH #update" do
    let!(:event) do
      Event.create!(
        event_name: "Original Event",
        event_date_time: 1.day.from_now,
        description: "Original description",
        point_value: 1,
        category: category,
        semester: semester
      )
    end

    it "updates the event check-in code" do
      patch :update,
            params: {
              id: event.id,
              event: { check_in_code: "5678" }
            }

      expect(event.reload.check_in_code).to eq("5678")
      expect(response).to redirect_to(admin_events_path)
    end

    it "allows the check-in code to be removed" do
      event.update!(check_in_code: "1234")

      patch :update,
            params: {
              id: event.id,
              event: { check_in_code: "" }
            }

      expect(event.reload.check_in_code).to be_blank
      expect(response).to redirect_to(admin_events_path)
    end
  end
end
