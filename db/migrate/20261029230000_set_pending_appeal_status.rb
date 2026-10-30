# frozen_string_literal: true

class SetPendingAppealStatus < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      UPDATE appeals
      SET status = COALESCE(NULLIF(LOWER(BTRIM(status)), ''), 'pending')
    SQL
    change_column_default :appeals, :status, from: nil, to: 'pending'
    change_column_null :appeals, :status, false
  end

  def down
    change_column_null :appeals, :status, true
    change_column_default :appeals, :status, from: 'pending', to: nil
  end
end
