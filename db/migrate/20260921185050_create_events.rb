class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events, if_not_exists: true do |t|
      t.references :category, null: false, foreign_key: true
      t.references :semester, null: false, foreign_key: true
      t.string :event_name
      t.datetime :event_date_time
      t.decimal :point_value

      t.timestamps
    end
  end
end