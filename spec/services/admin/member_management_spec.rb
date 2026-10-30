# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Admin::MemberManagement do
  let!(:actor_user) { User.create!(email: 'service-admin@tamu.edu', name: 'Service Admin') }
  let!(:actor) do
    Member.create!(user: actor_user, name: 'Service Admin', tamu_email: actor_user.email,
                   uin: 123456789, class_year: 2027, is_admin: true)
  end
  let!(:target_user) { User.create!(email: 'service-target@tamu.edu', name: 'Service Member') }
  let!(:target) do
    Member.create!(user: target_user, name: 'Service Member', tamu_email: target_user.email,
                   uin: 987654321, class_year: 2028, is_admin: false)
  end
  subject(:management) { described_class.new(actor: actor, member: target) }

  describe 'authorization after acquiring locks' do
    %i[promote! revoke! archive!].each do |operation|
      it "rechecks the stored admin role for #{operation}, rather than trusting a stale actor" do
        stale_actor = actor
        Member.find(actor.id).update!(is_admin: false)
        expect(stale_actor.is_admin?).to be(true)

        expect { management.public_send(operation) }.to raise_error(described_class::Error, 'Access denied.')
        expect(Member.exists?(target.id)).to be(true)
        expect(User.exists?(target_user.id)).to be(true)
        expect(target.reload).not_to be_is_admin
      end
    end

    it 'rechecks authorization for profile edits too' do
      Member.find(actor.id).update!(is_admin: false)

      expect { management.update(name: 'Not allowed') }.to raise_error(described_class::Error, 'Access denied.')
      expect(target.reload.name).to eq('Service Member')
    end

    it 'rejects a missing actor' do
      service = described_class.new(actor: nil, member: target)

      expect { service.promote! }.to raise_error(described_class::Error, 'Access denied.')
      expect(target.reload).not_to be_is_admin
    end
  end

  describe 'profile updates' do
    it 'only accepts editable profile fields even when called without a controller' do
      management.update(name: 'Allowed', user_id: actor_user.id, is_admin: true, points_adjustment: 999, archived_at: Time.current)

      expect(target.reload).to have_attributes(name: 'Allowed', user_id: target_user.id,
                                              is_admin: false, tamu_email: target_user.email, points_adjustment: 0, archived_at: nil)
    end

    it 'keeps normal profile validation on edits' do
      expect(management.update(uin: '')).to be(false)
      expect(target.errors[:uin]).not_to be_empty
      expect(target.reload.uin).to eq(987654321)
    end
  end

  describe 'role changes' do
    it 'does not save unrelated dirty attributes during a role change' do
      target.name = 'Unsaved local edit'

      management.promote!

      expect(target.reload).to be_is_admin
      expect(target.name).to eq('Service Member')
    end

    it 'still runs unconditional validations in the role-change context' do
      target.name = ''
      target.tamu_email = ''

      expect(target.valid?(:admin_role_change)).to be(false)
      expect(target.errors[:name]).not_to be_empty
      expect(target.errors[:tamu_email]).not_to be_empty
    end

    it 'does not modify an already-admin member when promotion is repeated' do
      target.update!(is_admin: true)
      original_timestamp = target.updated_at

      expect(management.promote!).to be(false)
      expect(target.reload.updated_at).to eq(original_timestamp)
    end
  end

  describe 'archival safeguards' do
    it 'retains the login and records which administrator archived the member' do
      expect { management.archive! }.not_to change(User, :count)
      expect(target.reload).to be_archived
      expect(target.archived_by_id).to eq(actor.id)
      expect(actor.reload).to be_is_admin
    end

    it 'refuses archival when one login is linked to multiple member records' do
      duplicate = Member.create!(user: target_user, name: 'Duplicate Link', tamu_email: 'duplicate-link@tamu.edu',
                                 uin: 456789123, class_year: 2028)
      expect { management.archive! }.to raise_error(described_class::Error, /more than one member/)
      expect(target.reload).not_to be_archived
      expect(duplicate.reload).not_to be_archived
    end

    it 'archives an incomplete seeded profile without requiring profile fields' do
      user = User.create!(email: 'incomplete-archive@tamu.edu')
      member = Member.create!(user: user, name: 'Incomplete', tamu_email: user.email)
      described_class.new(actor: actor, member: member).archive!
      expect(member.reload).to be_archived
    end

    it 'rejects a stale archived actor even if their stored role is still admin' do
      Member.find(actor.id).update!(archived_at: Time.current)
      expect { management.update(name: 'Forbidden') }.to raise_error(described_class::Error, 'Access denied.')
      expect(target.reload.name).to eq('Service Member')
    end

    %i[promote! revoke! archive!].each do |operation|
      it "refuses #{operation} for an archived member" do
        management.archive!
        expect { management.public_send(operation) }.to raise_error(described_class::Error, /archived/)
      end
    end

    it 'does not count an archived account as an active administrator' do
      target.update!(archived_at: Time.current, is_admin: true)
      service = described_class.new(actor: actor, member: actor)
      expect { service.revoke! }.to raise_error(described_class::Error, /last administrator/)
    end
  end
end
