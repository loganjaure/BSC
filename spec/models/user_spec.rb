# spec/models/user_spec.rb
require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'Associations' do
    it { should have_one(:member).dependent(:destroy) }
  end

  describe 'Validations' do
    it { should validate_presence_of(:email) }

    it 'allows valid TAMU email addresses' do
      user = User.new(email: 'aggie@tamu.edu', full_name: 'Aggie', uid: '123', provider: 'google_oauth2')
      expect(user).to be_valid
    end

    it 'rejects non-TAMU email addresses' do
      user = User.new(email: 'user@gmail.com', full_name: 'Outsider', uid: '123', provider: 'google_oauth2')
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include('must be an official TAMU email (@tamu.edu)')
    end
  end

  describe '.from_google' do
    it 'creates a new user for valid TAMU credentials' do
      expect {
        User.from_google(email: 'new_aggie@tamu.edu', full_name: 'New Aggie', uid: '999', provider: 'google_oauth2')
      }.to change(User, :count).by(1)
    end

    it 'returns existing user instead of duplicating' do
      existing = User.create!(email: 'existing@tamu.edu', full_name: 'Existing', uid: '111', provider: 'google_oauth2')
      result = User.from_google(email: 'existing@tamu.edu', full_name: 'Existing Updated', uid: '111', provider: 'google_oauth2')

      expect(result.id).to eq(existing.id)
      expect(User.where(email: 'existing@tamu.edu').count).to eq(1)
    end

    it 'returns nil for non-TAMU email' do
      result = User.from_google(email: 'hacker@gmail.com', full_name: 'Hacker', uid: '000', provider: 'google_oauth2')
      expect(result).to be_nil
    end
  end
end
