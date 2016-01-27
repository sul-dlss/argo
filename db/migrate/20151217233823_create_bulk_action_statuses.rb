class CreateBulkActionStatuses < ActiveRecord::Migration
  def change
    create_table :bulk_action_statuses do |t|
      t.boolean :success
      t.boolean :completed
      t.boolean :started

      t.timestamps null: false
      t.belongs_to :bulk_actions, index: true
    end
  end
end
