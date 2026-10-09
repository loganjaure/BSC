# spec/requests/sessions_spec.rb
require 'rails_helper'

RSpec.describe "Sessions / OAuth", type: :request do
  before do
    OmniAuth.config.test_mode = true
  end

  after do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  describe "GET /auth/google_oauth2/callback" do
    context "with valid TAMU Google account" do
      before do
        OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
          provider: 'google_oauth2',
          uid: '123456',
          info: {
            email: 'rev12@tamu.edu',
            name: 'Reveille XII'
          }
        })
      end

      it "logs in user and redirects appropriately" do
        get '/auth/google_oauth2/callback'
        expect(response).to redirect_to(root_path).or redirect_to(edit_member_path(Member.last))
        expect(session[:user_id]).not_to be_nil
      end
    end

    context "with non-TAMU email account" do
      before do
        OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
          provider: 'google_oauth2',
          uid: '654321',
          info: {
            email: 'outsider@gmail.com',
            name: 'External User'
          }
        })
      end

      it "denies login and redirects with an error flash" do
        get '/auth/google_oauth2/callback'
        expect(session[:user_id]).to be_nil
        expect(flash[:alert]).to be_present
      end
    end
  end

  describe "DELETE /logout or GET /logout" do
    it "clears session on logout" do
      delete '/logout' # Adjust path according to your routes.rb
      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(root_path)
    end
  end
end
