class CreateAppeals < ActiveRecord::Migration[7.0]
  def change
    create_table :appeals, if_not_exists: true do |t|
      t.references :submitting_member, null: false, foreign_key: { to_table: :members }
      t.references :event, null: false, foreign_key: true
      t.string :appeal_type
      t.text :reason
      t.string :status
      t.references :reviewed_by_member, foreign_key: { to_table: :members }

      t.timestamps
    end
  end
end