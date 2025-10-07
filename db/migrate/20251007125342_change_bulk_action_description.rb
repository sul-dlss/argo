class ChangeBulkActionDescription < ActiveRecord::Migration[8.0]
  def up
    change_column :bulk_actions, :description, :text
  end

  def down
    change_column :bulk_actions, :description, :string, limit: 255
  end
end
