# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Archived seed administrators' do
  it 'does not recreate or reactivate an archived administrator whose roster email was edited' do
    load Rails.root.join('db/seeds.rb')
    member = Member.find_by!(tamu_email: 'ruth_jasadiredja@tamu.edu')
    actor = Member.find_by!(tamu_email: 'loganjaure@tamu.edu')
    member.update!(tamu_email: 'edited-ruth@tamu.edu', uin: 987123456, class_year: 2027)
    Admin::MemberManagement.new(actor: actor, member: member).archive!
    original = member.reload.attributes

    expect { load Rails.root.join('db/seeds.rb') }.to change(Member, :count).by(0).and change(User, :count).by(0)
    expect(member.reload.attributes).to eq(original)
    expect(member).not_to be_is_admin
  end
end
