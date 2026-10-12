# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Admin member management', type: :request do
  let!(:admin_user) do
    User.create!(
      name: 'Acting Admin',
      full_name: 'Acting Admin',
      email: 'acting-admin@tamu.edu'
    )
  end

  let!(:admin_member) do
    Member.create!(
      user: admin_user,
      name: 'Acting Admin',
      tamu_email: admin_user.email,
      uin: 123456789,
      class_year: 2027,
      is_admin: true
    )
  end

  let!(:target_user) do
    User.create!(
      name: 'Test Member',
      full_name: 'Test Member',
      email: 'managed-member@tamu.edu'
    )
  end

  let!(:target) do
    Member.create!(
      user: target_user,
      name: 'Test Member',
      tamu_email: target_user.email,
      uin: 987654321,
      class_year: 2028,
      is_admin: false
    )
  end

  let(:category) do
    Category.create!(category_name: 'Management test category')
  end

  let(:semester) do
    Semester.create!(term_name: 'Fall 2026')
  end

  let(:event) do
    Event.create!(
      event_name: 'Member management test event',
      event_date_time: Time.current,
      point_value: 1,
      category: category,
      semester: semester,
      description: 'Test event for admin member management'
    )
  end

  def sign_in_as(user)
    user_id = user&.id

    # Read fresh records on every request so revocation/deletion tests cannot
    # accidentally keep using a cached admin role or a deleted login account.
    allow_any_instance_of(ApplicationController).to receive(:current_user) do
      User.find_by(id: user_id)
    end
  end

  before { sign_in_as(admin_user) }

  describe 'admin navigation' do
    it 'keeps the member list and exposes edit and deletion-confirmation links' do
      get admin_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        'View Details',
        'Edit Member',
        'Delete Member',
        target.tamu_email
      )
      expect(response.body).to include(
        edit_admin_member_path(target),
        delete_admin_member_path(target)
      )
    end

    it 'keeps member details and event history' do
      Attendance.create!(
        member: target,
        event: event,
        check_in_time: Time.current
      )

      get admin_member_path(target)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        event.event_name,
        'Total Points:',
        'Edit Member'
      )
    end

    it 'shows revoke for another admin but not for the acting admin' do
      target.update!(is_admin: true)

      get admin_path

      expect(response.body).to include(revoke_admin_member_path(target))
      expect(response.body).not_to include(revoke_admin_member_path(admin_member))
      expect(response.body).not_to include(delete_admin_member_path(admin_member))
    end
  end

  describe 'editing members' do
    it 'shows editable email and total points without role or user-link fields' do
      get edit_admin_member_path(target)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include(
        'member[name]',
        'member[uin]',
        'member[class_year]',
        'member[tamu_email]',
        'member[total_points]'
      )
      expect(response.body).not_to include(
        'member[is_admin]',
        'member[user_id]'
      )
    end

    it 'saves valid edits and shows them on the details page' do
      patch admin_member_path(target), params: {
        member: {
          name: 'Updated Member',
          uin: '555666777',
          class_year: '2029'
        }
      }

      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(admin_member_path(target))
      expect(target.reload).to have_attributes(
        name: 'Updated Member',
        uin: 555666777,
        class_year: 2029
      )

      follow_redirect!

      expect(response.body).to include('Updated Member', '555666777', '2029')
    end

    {
      blank_name: { name: '' },
      blank_uin: { uin: '' },
      short_uin: { uin: '123' },
      nonnumeric_uin: { uin: 'abcdefghi' },
      duplicate_uin: { uin: '123456789' },
      blank_class_year: { class_year: '' },
      early_class_year: { class_year: '2000' },
      late_class_year: { class_year: '2100' },
      nonnumeric_class_year: { class_year: 'invalid' },
      blank_email: { tamu_email: '' },
      non_tamu_email: { tamu_email: 'someone@gmail.com' },
      malformed_email: { tamu_email: 'invalid email@tamu.edu' },
      duplicate_email: { tamu_email: 'ACTING-ADMIN@TAMU.EDU' },
      blank_points: { total_points: '' },
      negative_points: { total_points: '-1' },
      invalid_points: { total_points: 'not-a-number' }
    }.each do |case_name, attributes|
      it "rejects #{case_name} and preserves the saved record" do
        original = target.attributes

        patch admin_member_path(target), params: { member: attributes }

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include('Please correct the following:')
        expect(target.reload.attributes).to eq(original)
      end
    end

    it 'preserves attempted valid fields when another field is invalid' do
      patch admin_member_path(target), params: {
        member: { name: 'Attempted Name', uin: '' }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('Attempted Name')
      expect(target.reload.name).to eq('Test Member')
    end

    it 'ignores forged role, archive, adjustment, and account-link parameters' do
      original = target.attributes.slice(
        'archived_at',
        'archived_by_id',
        'points_adjustment',
        'user_id',
        'is_admin',
        'standing'
      )

      patch admin_member_path(target), params: {
        member: {
          name: 'Allowed Name',
          archived_at: Time.current,
          archived_by_id: admin_member.id,
          points_adjustment: 999,
          user_id: admin_user.id,
          is_admin: true,
          standing: 'forged'
        }
      }

      expect(target.reload.name).to eq('Allowed Name')
      expect(
        target.attributes.slice('archived_at', 'archived_by_id', 'points_adjustment', 'user_id', 'is_admin', 'standing')
      ).to eq(original)
      expect(target_user.reload.email).to eq('managed-member@tamu.edu')
    end
  end

  describe 'administrator roles' do
    it 'promotes a regular member' do
      patch promote_admin_member_path(target)

      expect(target.reload).to be_is_admin
      expect(response).to redirect_to(admin_member_path(target))
    end

    it 'revokes another administrator without deleting their account or history' do
      target.update!(is_admin: true)
      attendance = Attendance.create!(
        member: target,
        event: event,
        check_in_time: Time.current
      )

      patch revoke_admin_member_path(target)

      expect(target.reload).not_to be_is_admin
      expect(User.exists?(target_user.id)).to be(true)
      expect(Attendance.exists?(attendance.id)).to be(true)
      expect(response).to have_http_status(:see_other)
      expect(response).to redirect_to(admin_member_path(target))
    end

    it 'allows the revoked admin to use member pages but denies admin pages' do
      target.update!(is_admin: true)
      patch revoke_admin_member_path(target)
      sign_in_as(target_user)

      get admin_path

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to eq('Access denied.')

      get member_path(target)

      expect(response).to have_http_status(:success)
    end

    it 'rejects self-revocation even when another administrator exists' do
      target.update!(is_admin: true)

      patch revoke_admin_member_path(admin_member)

      expect(admin_member.reload).to be_is_admin
      expect(flash[:alert]).to include('your own')
    end

    it 'rejects revoking the last administrator' do
      patch revoke_admin_member_path(admin_member)

      expect(admin_member.reload).to be_is_admin
      expect(flash[:alert]).to include('last administrator')
    end

    it 'handles repeated revocation without creating or deleting records' do
      patch revoke_admin_member_path(target)

      expect(target.reload).not_to be_is_admin
      expect(flash[:notice]).to include('already a member')
    end

    it 'can promote and revoke a newly seeded member with an incomplete profile' do
      new_user = User.create!(
        email: 'incomplete@tamu.edu',
        name: 'Incomplete Profile'
      )
      incomplete = Member.create!(
        user: new_user,
        name: 'Incomplete Profile',
        tamu_email: new_user.email
      )

      patch promote_admin_member_path(incomplete)

      expect(incomplete.reload).to be_is_admin

      patch revoke_admin_member_path(incomplete)

      expect(incomplete.reload).not_to be_is_admin
      expect(incomplete.uin).to be_nil
      expect(incomplete.class_year).to be_nil
    end
  end

  describe 'member archival' do
    it 'only displays confirmation on GET and does not archive anything' do
      expect { get delete_admin_member_path(target) }.not_to change { target.reload.archived_at }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Archive Member', 'confirm_delete', 'Cancel', 'retained')
    end

    it 'requires explicit confirmation even for a directly submitted DELETE request' do
      delete admin_member_path(target)

      expect(target.reload).not_to be_archived
      expect(response).to redirect_to(delete_admin_member_path(target))
    end

    it 'archives a member and retains their profile and application login' do
      original_profile = target.attributes.except('updated_at', 'archived_at', 'archived_by_id')
      expect do
        delete admin_member_path(target), params: { confirm_delete: '1' }
      end.to change(Member, :count).by(0).and change(User, :count).by(0)

      expect(target.reload).to be_archived
      expect(target.archived_by_id).to eq(admin_member.id)
      expect(target.attributes.except('updated_at', 'archived_at', 'archived_by_id')).to eq(original_profile)
      expect(response).to redirect_to(admin_path)
      expect(response).to have_http_status(:see_other)
    end

    it 'removes an archived member from the active roster and preserves admin access to their history' do
      delete admin_member_path(target), params: { confirm_delete: '1' }
      get admin_path
      expect(response.body).not_to include(target.tamu_email)

      get admin_path(archived: '1')
      expect(response.body).to include(target.tamu_email, 'Archived Members')
      expect(response.body).not_to include(edit_admin_member_path(target), delete_admin_member_path(target))

      get admin_member_path(target)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Archived on', target.tamu_email)
    end

    it 'rejects access for an archived login account' do
      delete admin_member_path(target), params: { confirm_delete: '1' }
      sign_in_as(target_user)
      get member_path(target)

      expect(response).to redirect_to(root_path)
      expect(flash[:alert]).to include('archived')
    end

    it 'blocks self-archival even when another administrator exists' do
      target.update!(is_admin: true)
      delete admin_member_path(admin_member), params: { confirm_delete: '1' }

      expect(admin_member.reload).not_to be_archived
      expect(flash[:alert]).to include('your own account')
    end

    it 'blocks archival of the last administrator' do
      delete admin_member_path(admin_member), params: { confirm_delete: '1' }

      expect(admin_member.reload).not_to be_archived
      expect(flash[:alert]).to include('last administrator')
    end

    it 'archives another administrator and clears their admin role' do
      target.update!(is_admin: true)
      delete admin_member_path(target), params: { confirm_delete: '1' }

      expect(target.reload).to be_archived
      expect(target).not_to be_is_admin
      expect(admin_member.reload).to be_is_admin
    end

    it 'retains attendance and adjusted points while archiving a member with history' do
      attendance = Attendance.create!(member: target, event: event, check_in_time: Time.current)
      target.update!(total_points: '7.5')
      delete admin_member_path(target), params: { confirm_delete: '1' }

      expect(target.reload).to be_archived
      expect(Attendance.exists?(attendance.id)).to be(true)
      expect(target.total_points).to eq(7.5)
      get admin_member_path(target)
      expect(response.body).to include(event.event_name, '7.5')
    end

    it 'retains attendance added after opening the confirmation page' do
      get delete_admin_member_path(target)
      attendance = Attendance.create!(member: target, event: event, check_in_time: Time.current)
      delete admin_member_path(target), params: { confirm_delete: '1' }

      expect(target.reload).to be_archived
      expect(Attendance.exists?(attendance.id)).to be(true)
    end

    it 'retains submitted appeals' do
      appeal = Appeal.create!(submitting_member: target, event: event,
                             appeal_type: 'attendance', reason: 'Test appeal', status: 'pending')
      delete admin_member_path(target), params: { confirm_delete: '1' }

      expect(target.reload).to be_archived
      expect(appeal.reload.submitting_member_id).to eq(target.id)
    end

    it 'retains reviewed appeals and their submitting member' do
      target.update!(is_admin: true)
      appeal = Appeal.create!(submitting_member: admin_member, reviewed_by_member: target, event: event,
                             appeal_type: 'attendance', reason: 'Test appeal', status: 'pending')
      delete admin_member_path(target), params: { confirm_delete: '1' }

      expect(target.reload).to be_archived
      expect(admin_member.reload).to be_is_admin
      expect(appeal.reload.reviewed_by_member_id).to eq(target.id)
    end

    it 'does not alter an archived record on repeated requests' do
      delete admin_member_path(target), params: { confirm_delete: '1' }
      original = target.reload.attributes
      delete admin_member_path(target), params: { confirm_delete: '1' }
      patch admin_member_path(target), params: { member: { name: 'Changed', total_points: '100' } }
      patch promote_admin_member_path(target)

      expect(target.reload.attributes).to eq(original)
    end
  end

  describe 'email and point corrections' do
    it 'saves the member email and points without changing Google identity or attendance' do
      attendance = Attendance.create!(member: target, event: event, check_in_time: Time.current)
      original_login = target_user.attributes
      patch admin_member_path(target), params: { member: { tamu_email: ' CORRECTED@TAMU.EDU ', total_points: '8.5' } }

      expect(response).to redirect_to(admin_member_path(target))
      expect(target.reload.tamu_email).to eq('corrected@tamu.edu')
      expect(target.total_points).to eq(8.5)
      expect(target.points_adjustment).to eq(7.5)
      expect(attendance.reload.event_id).to eq(event.id)
      expect(event.reload.point_value).to eq(1)
      expect(target_user.reload.attributes).to eq(original_login)

      sign_in_as(target_user)
      get member_path(target)
      expect(response.body).to include('corrected@tamu.edu', '8.5')
    end

    it 'continues adding attendance points after a total correction' do
      patch admin_member_path(target), params: { member: { total_points: '5' } }
      Attendance.create!(member: target, event: event, check_in_time: Time.current)

      expect(target.reload.total_points).to eq(6)
    end

    it 'does not save an email or point correction when profile validation fails' do
      original = target.attributes
      patch admin_member_path(target), params: {
        member: { name: '', tamu_email: 'attempted@tamu.edu', total_points: '4.5' }
      }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include('attempted@tamu.edu', '4.5')
      expect(target.reload.attributes).to eq(original)
    end
  end

  describe 'authorization for every member-management endpoint' do
    [
      [ :get, :admin_path, false ],
      [ :get, :admin_member_path, true ],
      [ :get, :edit_admin_member_path, true ],
      [ :get, :delete_admin_member_path, true ],
      [ :patch, :admin_member_path, true ],
      [ :patch, :promote_admin_member_path, true ],
      [ :patch, :revoke_admin_member_path, true ],
      [ :delete, :admin_member_path, true ]
    ].each do |verb, helper, needs_member|
      [ false, true ].each do |signed_out|
        it "denies #{signed_out ? 'signed-out visitors' : 'ordinary members'} on #{verb.upcase} #{helper}" do
          sign_in_as(signed_out ? nil : target_user)

          original_member = admin_member.attributes
          original_users = User.count
          original_members = Member.count
          path = needs_member ? public_send(helper, admin_member) : public_send(helper)

          public_send(
            verb,
            path,
            params: {
              member: { name: 'Unauthorized edit', is_admin: true },
              confirm_delete: '1'
            }
          )

          expect(response).to redirect_to(root_path)
          expect(admin_member.reload.attributes).to eq(original_member)
          expect(User.count).to eq(original_users)
          expect(Member.count).to eq(original_members)
          expect(target.reload).not_to be_is_admin
        end
      end
    end

    it 'prevents a member from granting themselves admin access by direct request' do
      sign_in_as(target_user)

      patch promote_admin_member_path(target)

      expect(target.reload).not_to be_is_admin
      expect(response).to redirect_to(root_path)
    end
  end
end
