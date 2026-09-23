# spec/requests/members_spec.rb
require 'rails_helper'

RSpec.describe "Members", type: :request do
  let!(:user) { User.create!(email: 'student@tamu.edu', full_name: 'Aggie Student', uid: '12345', provider: 'google_oauth2') }
  let!(:member) { Member.create!(name: user.full_name, tamu_email: user.email, uin: '123456789', class_year: 2026, user: user) }

  before do
    # Simulates logged-in user in session
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
    allow_any_instance_of(ApplicationController).to receive(:current_member).and_return(member)
  end

  describe "GET /show" do
    it "returns http success" do
      get member_path(member)
      expect(response).to have_http_status(:success)
    end
  end

  describe "GET /edit" do
    it "returns http success" do
      get edit_member_path(member)
      expect(response).to have_http_status(:success)
    end
  end
end