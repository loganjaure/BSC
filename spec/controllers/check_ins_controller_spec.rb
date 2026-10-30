
# frozen_string_literal: true

require "rails_helper"

RSpec.describe CheckInsController, type: :controller do
  let!(:user) do
    User.create!(
      email: "checkin_test@tamu.edu",
      full_name: "Check-in Test"
    )
  end

  let!(:member) do
    Member.create!(
      user: user,
      name: "Check-in Test",
      tamu_email: "checkin_test@tamu.edu",
      uin: 123456789,
      class_year: 2027
    )
  end

  let!(:category) do
    Category.create!(category_name: "Check-in Category")
  end

  let!(:semester) do
    Semester.create!(term_name: "Check-in Semester")
  end

  let!(:event) do
    Event.create!(
      event_name: "Test Event",
      event_date_time: 1.hour.ago,
      description: "Test event description",
      point_value: 1,
      category: category,
      semester: semester
    )
  end

  before do
    session[:user_id] = user.id
  end

  describe "GET #show" do
    it "renders the check-in page for an active event" do
      get :show, params: { id: event.id }

      expect(response).to have_http_status(:ok)
    end

    it "redirects when the event is not active" do
      event.update!(event_date_time: 4.hours.ago)

      get :show, params: { id: event.id }

      expect(response).to redirect_to(root_path)
    end
  end

  describe "POST #create" do
    context "when the event does not require a code" do
      it "creates an attendance record" do
        expect {
          post :create,
               params: { id: event.id, check_in_code: "" },
               format: :json
        }.to change(Attendance, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["checked_in"]).to be true
      end
    end

    context "when the event requires a code" do
      before do
        event.update!(check_in_code: "1234")
      end

      it "allows check-in with the correct code" do
        expect {
          post :create,
               params: { id: event.id, check_in_code: "1234" },
               format: :json
        }.to change(Attendance, :count).by(1)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["checked_in"]).to be true
      end

      it "rejects an incorrect code" do
        expect {
          post :create,
               params: { id: event.id, check_in_code: "9999" },
               format: :json
        }.not_to change(Attendance, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to include("Incorrect")
      end

      it "rejects a missing code" do
        expect {
          post :create,
               params: { id: event.id },
               format: :json
        }.not_to change(Attendance, :count)

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when the event is outside the check-in window" do
      before do
        event.update!(event_date_time: 4.hours.ago)
      end

      it "does not create an attendance record" do
        expect {
          post :create,
               params: { id: event.id },
               format: :json
        }.not_to change(Attendance, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)["error"]).to include("isn't open")
      end
    end

    context "when the member has already checked in" do
      before do
        Attendance.create!(
          member: member,
          event: event,
          check_in_time: Time.current,
          status: "present"
        )
      end

      it "does not create a duplicate attendance record" do
        expect {
          post :create,
               params: { id: event.id },
               format: :json
        }.not_to change(Attendance, :count)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)["checked_in"]).to be true
      end
    end
  end
end
