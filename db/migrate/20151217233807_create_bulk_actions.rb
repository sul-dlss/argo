class CreateBulkActions < ActiveRecord::Migration
  def change
    create_table :bulk_actions do |t|
      t.datetime :start_time
      t.datetime :end_time
      t.integer :bulk_actionable_id
      t.string :bulk_actionable_type

      t.timestamps null: false
      t.belongs_to :user, index: true
    end
    add_index :bulk_actions, [:bulk_actionable_id, :bulk_actionable_type], name: 'bulk_actionable_index'
  end
end
