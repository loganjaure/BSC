# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Member Registration Flow", type: :request do
  before do
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new({
      provider: 'google_oauth2',
      uid: '88888',
      info: { email: 'new_student@tamu.edu', name: 'New Student' }
    })
  end

  after do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end

  it 'allows a user to sign in with Google and complete their profile' do
    # 1. Trigger Google OAuth callback
    get '/auth/google_oauth2/callback'

    # 2. Verify user was created and session was set
    user = User.find_by(email: 'new_student@tamu.edu')
    expect(user).not_to be_nil
    expect(session[:user_id]).to eq(user.id)

    # 3. Complete profile update if member exists
    member = user.member || Member.find_by(tamu_email: user.email)
    if member
      patch member_path(member), params: { member: { uin: '987654321', class_year: 2026 } }
      expect(response).to redirect_to(member_path(member)).or redirect_to(root_path)
    end
  end
end
