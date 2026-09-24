# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Member, type: :model do
  describe 'Associations' do
    it { should belong_to(:user).optional }
    it { should have_many(:attendances).dependent(:destroy) }
    it { should have_many(:events).through(:attendances) }
    it { should have_many(:submitted_appeals).class_name('Appeal').with_foreign_key('submitting_member_id') }
    it { should have_many(:reviewed_appeals).class_name('Appeal').with_foreign_key('reviewed_by_member_id') }
  end

  describe 'Validations' do
    let(:user) { User.create!(email: 'test@tamu.edu', full_name: 'Test User', uid: '12345', provider: 'google_oauth2') }
    subject { Member.new(uin: '123456789', tamu_email: 'test@tamu.edu', name: 'Test User', class_year: 2026, user: user) }

    # Always required
    it { should validate_presence_of(:name).with_message('cannot be blank') }
    it { should validate_presence_of(:tamu_email) }
    it { should validate_uniqueness_of(:tamu_email) }

    # Required ONLY on :update
    context 'on update' do
      it { should validate_presence_of(:uin).on(:update).with_message('cannot be blank') }
      it { should validate_uniqueness_of(:uin).on(:update).case_insensitive }

      it { should validate_presence_of(:class_year).on(:update).with_message('cannot be blank') }

      it 'validates numericality and length of uin on update' do
        member = Member.create!(name: 'Test User', tamu_email: 'test_uin@tamu.edu', user: user)
        member.uin = 'abc'
        expect(member.valid?(:update)).to be false
        expect(member.errors[:uin]).to include('must be numeric ')

        member.uin = '123'
        expect(member.valid?(:update)).to be false
        expect(member.errors[:uin]).to include('must be exactly 9 digits')
      end

      it 'validates class_year range on update' do
        member = Member.create!(name: 'Test User', tamu_email: 'test_year@tamu.edu', user: user)
        member.class_year = 1999
        expect(member.valid?(:update)).to be false
        expect(member.errors[:class_year]).to include('must be a valid 4-digit year')
      end
    end

    context 'on initial OAuth creation' do
      it 'is valid without uin and class_year' do
        member = Member.new(name: 'OAuth User', tamu_email: 'oauth@tamu.edu', user: user)
        expect(member).to be_valid
      end
    end
  end
end
