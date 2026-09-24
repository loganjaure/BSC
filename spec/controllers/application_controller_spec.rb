# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApplicationController, type: :controller do
  controller do
    before_action :require_login, only: [ :index ]

    def index
      render plain: 'secure area'
    end
  end

  describe '#require_login' do
    context 'when unauthenticated' do
      it 'redirects to root path' do
        get :index
        expect(response).to redirect_to(root_path)
      end
    end

    context 'when authenticated' do
      it 'allows access' do
        user = User.create!(email: 'auth_user@tamu.edu', full_name: 'Auth User', uid: '789', provider: 'google_oauth2')
        session[:user_id] = user.id

        get :index
        expect(response).to have_http_status(:ok)
        expect(response.body).to eq('secure area')
      end
    end
  end
end
