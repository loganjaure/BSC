require 'rails_helper'

RSpec.describe Member, type: :model do
  describe 'Associations' do
    it { should have_many(:attendances) }
    it { should have_many(:events).through(:attendances) }
    it { should have_many(:submitted_appeals).class_name('Appeal').with_foreign_key('submitting_member_id') }
    it { should have_many(:reviewed_appeals).class_name('Appeal').with_foreign_key('reviewed_by_member_id') }
  end

  describe 'Validations' do
    subject { Member.new(uin: 123456789, tamu_email: 'test@tamu.edu', name: 'Test User') }

    it { should validate_presence_of(:uin) }
    it { should validate_uniqueness_of(:uin) }
    it { should validate_presence_of(:tamu_email) }
    it { should validate_uniqueness_of(:tamu_email) }
    it { should validate_presence_of(:name) }
  end
end
