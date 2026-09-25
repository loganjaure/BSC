class AddUniqueIndexToAttendances < ActiveRecord::Migration[8.0]
  def change
    add_index :attendances, [ :member_id, :event_id ], unique: true
  end
end
