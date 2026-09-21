# frozen_string_literal: true

class CreateSemesterRequirements < ActiveRecord::Migration[8.0]
  def change
    create_table :semester_requirements do |t|
      t.references :semester, null: false, foreign_key: true
      t.references :category, null: false, foreign_key: true
      t.integer :required_count

      t.timestamps
    end
  end
end
