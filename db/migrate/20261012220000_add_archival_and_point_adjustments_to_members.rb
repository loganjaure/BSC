# frozen_string_literal: true

class AddArchivalAndPointAdjustmentsToMembers < ActiveRecord::Migration[8.1]
  def change
    add_column :members, :archived_at, :datetime
    add_reference :members, :archived_by, foreign_key: { to_table: :members }
    add_column :members, :points_adjustment, :decimal, default: 0, null: false
    add_index :members, :archived_at
    add_index :members, 'LOWER(tamu_email)', unique: true, name: 'index_members_on_normalized_email'
    add_index :users, 'LOWER(email)', unique: true, name: 'index_users_on_normalized_email'
    add_index :users, %i[provider uid], unique: true,
              where: "uid IS NOT NULL AND uid <> '' AND provider IS NOT NULL AND provider <> ''",
              name: 'index_users_on_google_identity'
  end
end
