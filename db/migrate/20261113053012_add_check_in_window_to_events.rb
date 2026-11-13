class AddCheckInWindowToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :check_in_opens_minutes_before,
               :integer, default: 15, null: false

    add_column :events, :check_in_closes_minutes_after,
               :integer, default: 60, null: false
  end
end
