# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Member identity and archival', type: :request do
  let!(:admin_user) { User.create!(email: 'identity-admin@tamu.edu', uid: 'admin-uid', provider: 'google_oauth2') }
  let!(:admin) do
    Member.create!(user: admin_user, name: 'Identity Admin', tamu_email: admin_user.email,
                   uin: 111222333, class_year: 2027, is_admin: true)
  end
  let!(:user) { User.create!(email: 'identity-member@tamu.edu', uid: 'member-uid', provider: 'google_oauth2') }
  let!(:member) do
    Member.create!(user: user, name: 'Identity Member', tamu_email: user.email,
                   uin: 444555666, class_year: 2028)
  end
  let(:management) { Admin::MemberManagement.new(actor: admin, member: member) }

  around do |example|
    original_mode = OmniAuth.config.test_mode
    original_auth = OmniAuth.config.mock_auth[:google_oauth2]
    OmniAuth.config.test_mode = true
    example.run
  ensure
    OmniAuth.config.test_mode = original_mode
    OmniAuth.config.mock_auth[:google_oauth2] = original_auth
  end

  def google_sign_in(email: user.email, uid: user.uid)
    OmniAuth.config.mock_auth[:google_oauth2] = OmniAuth::AuthHash.new(
      provider: 'google_oauth2', uid: uid, info: { email: email, name: 'Google Member' }
    )
    get '/auth/google_oauth2/callback'
  end

  it 'keeps the same account and edited profile email across Google sign-ins' do
    management.update(tamu_email: 'edited-roster@tamu.edu', total_points: '9.25')
    expect { google_sign_in }.to change(User, :count).by(0).and change(Member, :count).by(0)
    expect(session[:user_id]).to eq(user.id)
    expect(member.reload.tamu_email).to eq('edited-roster@tamu.edu')
    get member_path(member)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('edited-roster@tamu.edu', '9.25')
  end

  it 'finds a Google account by UID when its Google email changes' do
    expect { google_sign_in(email: 'renamed-google@tamu.edu') }.not_to change(User, :count)
    expect(session[:user_id]).to eq(user.id)
    expect(user.reload.email).to eq('renamed-google@tamu.edu')
    expect(member.reload.user_id).to eq(user.id)
  end

  it 'does not let a different Google identity take over an existing login by email' do
    google_sign_in(uid: 'different-google-uid')
    expect(session[:user_id]).to be_nil
    expect(user.reload.uid).to eq('member-uid')
  end

  it 'links an unclaimed seeded login on its first sign-in' do
    user.update!(uid: nil, provider: nil)
    google_sign_in(uid: 'first-google-uid')
    expect(session[:user_id]).to eq(user.id)
    expect(user.reload.uid).to eq('first-google-uid')
  end

  it 'does not link someone else to a member through an edited roster email' do
    management.update(tamu_email: 'other-google@tamu.edu')
    expect do
      google_sign_in(email: 'other-google@tamu.edu', uid: 'other-uid')
    end.to change(User, :count).by(0).and change(Member, :count).by(0)
    expect(session[:user_id]).to be_nil
    expect(member.reload.user_id).to eq(user.id)
  end

  it 'invalidates an existing session after archival' do
    google_sign_in
    expect(session[:user_id]).to eq(user.id)
    management.archive!
    get member_path(member)
    expect(response).to redirect_to(root_path)
    expect(session[:user_id]).to be_nil
    expect(flash[:alert]).to include('archived')
    follow_redirect!
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Sign in with Google')
  end

  it 'blocks re-registration using the archived Google account' do
    management.archive!
    original = member.reload.attributes
    expect { google_sign_in }.to change(User, :count).by(0).and change(Member, :count).by(0)
    expect(session[:user_id]).to be_nil
    expect(member.reload.attributes).to eq(original)
    expect(flash[:alert]).to include('archived')
  end

  it 'still blocks an archived Google UID with a different email' do
    management.update(tamu_email: 'edited-before-archive@tamu.edu')
    management.archive!
    expect do
      google_sign_in(email: 'new-google-email@tamu.edu')
    end.to change(User, :count).by(0).and change(Member, :count).by(0)
    expect(session[:user_id]).to be_nil
  end

  it 'blocks an archived seeded account before its first Google sign-in' do
    user.update!(uid: nil, provider: nil)
    management.archive!
    google_sign_in(uid: 'seed-first-uid')
    expect(session[:user_id]).to be_nil
    expect(user.reload.uid).to be_nil
  end

  it 'does not count archived members as signed in on the public home page' do
    google_sign_in
    management.archive!
    get root_path
    expect(session[:user_id]).to be_nil
    follow_redirect!
    expect(response.body).to include('Sign in with Google')
  end

  it 'prevents members from viewing or changing another member through the ordinary profile route' do
    google_sign_in
    get member_path(admin)
    expect(response).to have_http_status(:not_found)
    get edit_member_path(admin)
    expect(response).to have_http_status(:not_found)
    patch member_path(admin), params: { member: { name: 'Unauthorized', total_points: '100' } }
    expect(response).to have_http_status(:not_found)
    expect(admin.reload.name).to eq('Identity Admin')
  end

  it 'prevents a member from forging their own email, points, role, or archive state' do
    google_sign_in
    patch member_path(member), params: {
      member: { name: 'Allowed Name', tamu_email: 'forged@tamu.edu', total_points: '100',
                points_adjustment: 100, is_admin: true, archived_at: Time.current }
    }
    expect(member.reload).to have_attributes(name: 'Allowed Name', tamu_email: user.email,
                                             points_adjustment: 0, is_admin: false, archived_at: nil)
  end
end
