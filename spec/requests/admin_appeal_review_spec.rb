# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Attendance appeal review', type: :request do
  let!(:admin_user) { User.create!(email: 'appeal-admin@tamu.edu') }
  let!(:admin) do
    Member.create!(user: admin_user, name: 'Appeal Admin', tamu_email: admin_user.email,
                   uin: 123456789, class_year: 2027, is_admin: true)
  end
  let!(:member_user) { User.create!(email: 'appealing-member@tamu.edu') }
  let!(:member) do
    Member.create!(user: member_user, name: 'Appealing Member', tamu_email: member_user.email,
                   uin: 987654321, class_year: 2028)
  end
  let!(:event) do
    Event.create!(event_name: 'Appealed Meeting', event_date_time: 2.days.ago, point_value: 2.5,
                  description: 'Attendance appeal test', category: Category.create!(category_name: 'Meeting'),
                  semester: Semester.create!(term_name: 'Fall 2026'))
  end
  let!(:appeal) do
    Appeal.create!(submitting_member: member, event: event, appeal_type: 'attendance',
                   reason: 'I attended, but the check-in failed.')
  end

  def sign_in_as(user)
    user_id = user&.id
    allow_any_instance_of(ApplicationController).to receive(:current_user) { User.find_by(id: user_id) }
  end

  def document
    Nokogiri::HTML(response.body)
  end

  before { sign_in_as(admin_user) }

  it 'shows only pending appeals in the admin dashboard and keeps decided appeals in history' do
    decided = Appeal.create!(submitting_member: member, event: event, appeal_type: 'attendance',
                             reason: 'Already reviewed', status: 'denied', reviewed_by_member: admin)
    get admin_path
    expect(response).to have_http_status(:ok)
    expect(document.css('a').map { |link| link['href'] }).to include(admin_appeal_path(appeal))
    expect(document.css('a').map { |link| link['href'] }).not_to include(admin_appeal_path(decided))
    get admin_appeals_path
    expect(response.body).to include(admin_appeal_path(decided))
  end

  it 'shows the required details and two decision buttons on a pending appeal' do
    get admin_appeal_path(appeal)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(member.name, member.uin.to_s, member.tamu_email,
                                     event.event_name, appeal.created_at.strftime('%B %d, %Y at %I:%M %p'), appeal.reason)
    expect(document.css('button[name="decision"]:not([disabled])').size).to eq(2)
  end

  it 'approves attendance and adds event points while preserving the administrator adjustment' do
    member.update!(total_points: '4')
    expect do
      patch admin_appeal_path(appeal), params: { decision: 'approved' }
    end.to change(Attendance, :count).by(1)
    expect(response).to redirect_to(admin_appeal_path(appeal))
    expect(appeal.reload).to have_attributes(status: 'approved', reviewed_by_member_id: admin.id)
    expect(member.reload.total_points).to eq(6.5)
    expect(member.points_adjustment).to eq(4)
    expect(member.attendances.find_by!(event: event).status).to eq('present')
  end

  it 'denies without changing any attendance or points' do
    member.update!(total_points: '4')
    original = member.attributes
    expect do
      patch admin_appeal_path(appeal), params: { decision: 'denied' }
    end.not_to change(Attendance, :count)
    expect(appeal.reload).to have_attributes(status: 'denied', reviewed_by_member_id: admin.id)
    expect(member.reload.attributes).to eq(original)
    expect(member.total_points).to eq(4)
  end

  %w[approved denied].each do |decision|
    it "disables both buttons after #{decision} and displays the decision to the submitting member" do
      patch admin_appeal_path(appeal), params: { decision: decision }
      follow_redirect!
      expect(document.css('button[disabled]').map(&:text)).to include('Approve', 'Deny')
      expect(document.css('form[action]').map { |form| form['action'] }).not_to include(admin_appeal_path(appeal))
      sign_in_as(member_user)
      get appeals_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(decision.capitalize, event.event_name)
    end

    it "cannot repeat or reverse a #{decision} decision using a direct request" do
      patch admin_appeal_path(appeal), params: { decision: decision }
      original = appeal.reload.attributes
      points = member.reload.total_points
      count = Attendance.count
      %w[approved denied].each do |attempt|
        patch admin_appeal_path(appeal), params: { decision: attempt }
        expect(flash[:alert]).to include('already been reviewed')
        expect(appeal.reload.attributes).to eq(original)
        expect(member.reload.total_points).to eq(points)
        expect(Attendance.count).to eq(count)
      end
    end
  end

  it 'does not duplicate an existing check-in or award points again' do
    attendance = Attendance.create!(member: member, event: event, status: 'present', check_in_time: 1.day.ago)
    original = attendance.attributes
    expect do
      patch admin_appeal_path(appeal), params: { decision: 'approved' }
    end.not_to change(Attendance, :count)
    expect(attendance.reload.attributes).to eq(original)
    expect(member.reload.total_points).to eq(2.5)
    expect(appeal.reload.status).to eq('approved')
  end

  it 'credits one attendance when multiple pending appeals concern the same member and event' do
    second = Appeal.create!(submitting_member: member, event: event, appeal_type: 'attendance', reason: 'Second request')
    patch admin_appeal_path(appeal), params: { decision: 'approved' }
    expect do
      patch admin_appeal_path(second), params: { decision: 'approved' }
    end.not_to change(Attendance, :count)
    expect(member.reload.total_points).to eq(2.5)
  end

  it 'does not accept a forged status, reviewer, member, event, or reason' do
    original = appeal.attributes
    patch admin_appeal_path(appeal), params: {
      decision: 'invalid', appeal: { status: 'approved', reviewed_by_member_id: member.id,
                                    submitting_member_id: admin.id, event_id: 0, reason: 'Forged' }
    }
    expect(appeal.reload.attributes).to eq(original)
    expect(Attendance.count).to eq(0)
    expect(flash[:alert]).to include('Select Approve or Deny')
  end

  it 'ignores forged appeal attributes when processing a valid decision' do
    original = appeal.attributes.slice('submitting_member_id', 'event_id', 'reason')
    patch admin_appeal_path(appeal), params: {
      decision: 'approved', appeal: { status: 'denied', reviewed_by_member_id: member.id,
                                     submitting_member_id: admin.id, event_id: 0, reason: 'Forged' }
    }
    expect(appeal.reload.attributes.slice('submitting_member_id', 'event_id', 'reason')).to eq(original)
    expect(appeal).to have_attributes(status: 'approved', reviewed_by_member_id: admin.id)
  end

  it 'rechecks the reviewers role inside the transaction' do
    stale_actor = Member.find(admin.id)
    admin.update!(is_admin: false)
    expect do
      Admin::AppealReview.new(actor: stale_actor, appeal: appeal).decide!('approved')
    end.to raise_error(Admin::AppealReview::Error, 'Access denied.')
    expect(appeal.reload.status).to eq('pending')
    expect(Attendance.count).to eq(0)
  end

  it 'rolls back attendance if saving the decision fails' do
    allow_any_instance_of(Appeal).to receive(:update!).and_raise(ActiveRecord::RecordInvalid.new(appeal))
    expect do
      patch admin_appeal_path(appeal), params: { decision: 'approved' }
    end.not_to change(Attendance, :count)
    expect(appeal.reload.status).to eq('pending')
    expect(member.reload.total_points).to eq(0)
  end

  it 'cannot approve an archived member but can deny their pending appeal' do
    member.update!(archived_at: Time.current)
    patch admin_appeal_path(appeal), params: { decision: 'approved' }
    expect(appeal.reload.status).to eq('pending')
    expect(Attendance.count).to eq(0)
    patch admin_appeal_path(appeal), params: { decision: 'denied' }
    expect(appeal.reload.status).to eq('denied')
  end

  it 'keeps other members appeals private' do
    other = Appeal.create!(submitting_member: admin, event: event, appeal_type: 'attendance', reason: 'Private admin reason')
    sign_in_as(member_user)
    get appeals_path
    expect(response.body).to include(appeal.reason)
    expect(response.body).not_to include(other.reason, 'Review Member Appeals')
  end

  it 'escapes reasoning text rather than rendering submitted HTML' do
    appeal.update!(reason: '<script>alert(1)</script>')
    get admin_appeal_path(appeal)
    expect(response.body).to include('&lt;script&gt;')
    expect(response.body).not_to include('<script>alert(1)</script>')
  end

  [ nil, :member, :archived_admin ].each do |identity|
    it "rejects #{identity || 'signed-out visitors'} from every review endpoint" do
      admin.update!(archived_at: Time.current) if identity == :archived_admin
      sign_in_as(identity == :member ? member_user : (identity == :archived_admin ? admin_user : nil))
      original = appeal.attributes
      [ [ :get, admin_appeals_path ], [ :get, admin_appeal_path(appeal) ], [ :patch, admin_appeal_path(appeal) ] ].each do |verb, path|
        public_send(verb, path, params: { decision: 'approved' })
        expect(response).to redirect_to(root_path)
        expect(appeal.reload.attributes).to eq(original)
        expect(Attendance.count).to eq(0)
      end
    end
  end
end
