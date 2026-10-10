# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Support page', type: :request do
  let(:user) { User.create!(email: 'helpme@tamu.edu') }
  let!(:member) { Member.create!(user: user, name: 'Help Member', tamu_email: 'helpme@tamu.edu', uin: '123456789', class_year: 2027) }

  after { OmniAuth.config.mock_auth[:google_oauth2] = nil }

  def sign_in
    OmniAuth.config.test_mode = true
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google_oauth2', uid: '55555', info: { email: user.email, name: member.name }
    )
    get '/auth/google_oauth2/callback'
  end

  # AC-23.1: help content is available without contacting the dev team
  describe 'GET /support' do
    it 'is reachable without signing in' do
      get support_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Back to sign in')
    end

    it 'covers each main task in the app' do
      get support_path

      [ 'Signing in', '@tamu.edu', 'Checking in to an event', 'Viewing your points',
        'Category requirements', 'Satisfied', 'Appeals', 'For admins' ].each do |text|
        expect(response.body).to include(text)
      end
    end

    it 'loads for a signed-in member without the sign-in link' do
      sign_in
      get support_path

      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include('Back to sign in')
    end
  end

  # AC-23.1: the Help link in the nav and the sign-in page both lead to the support page
  describe 'Help links' do
    it 'shows a Help link in the navbar for signed-in members that opens the support page' do
      sign_in
      get root_path

      link = Nokogiri::HTML(response.body).css('nav.bsc-nav a').find { |a| a.text.strip == 'Help' }
      expect(link).not_to be_nil

      get link['href']
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Help &amp; Support')
    end

    it 'shows a "Need help?" link on the sign-in page' do
      get root_path

      link = Nokogiri::HTML(response.body).css('a').find { |a| a.text.strip == 'Need help?' }
      expect(link['href']).to eq(support_path)
    end
  end
end
