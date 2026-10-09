class SetIsAdminDefault < ActiveRecord::Migration[8.0]
  def change
    change_column_default :members, :is_admin, false
    change_column_null :members, :is_admin, false, false
  end
end
