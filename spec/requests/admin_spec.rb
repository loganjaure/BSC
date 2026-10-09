require 'rails_helper'

RSpec.describe "Admins", type: :request do
  describe "GET /index" do
    let!(:user) { User.create!(email: "admin@tamu.edu") }
    let!(:member) { Member.create!(user: user, name: "Admin Member", tamu_email: "admin@tamu.edu", uin: "123004567", class_year: 2025) }

    before do
      # 1. Allow current_user on both ApplicationController and AdminController
      allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
      allow_any_instance_of(AdminController).to receive(:current_user).and_return(user)

      # 2. Bypass common auth / admin filter methods
      [ :require_login, :require_admin, :check_admin, :authenticate_user! ].each do |method_name|
        allow_any_instance_of(ApplicationController).to receive(method_name).and_return(true) if ApplicationController.method_defined?(method_name) || ApplicationController.private_method_defined?(method_name)
        allow_any_instance_of(AdminController).to receive(method_name).and_return(true) if AdminController.method_defined?(method_name) || AdminController.private_method_defined?(method_name)
      end
    end

    it "returns http success" do
      get admin_path
      expect(response).to have_http_status(:success)
    end
  end
end
