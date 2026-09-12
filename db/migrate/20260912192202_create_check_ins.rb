# frozen_string_literal: true

class CreateCheckIns < ActiveRecord::Migration[8.0]
  def change
    create_table :check_ins do |t|
      t.integer :member_id
      t.integer :event_id

      t.timestamps
    end
  end
end
