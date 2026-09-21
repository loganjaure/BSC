class CreateSemesters < ActiveRecord::Migration[8.0]
  def change
    create_table :semesters do |t|
      t.string :term_name

      t.timestamps
    end
  end
end
