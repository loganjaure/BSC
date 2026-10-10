# frozen_string_literal: true

class CreateMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :members do |t|
      t.integer :uin
      t.string :tamu_email
      t.string :name
      t.integer :class_year
      t.boolean :is_admin, default: false, null: false
      t.string :standing

      t.timestamps
    end
  end
end
