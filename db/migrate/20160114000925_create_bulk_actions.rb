class CreateBulkActions < ActiveRecord::Migration[4.2]
  def change
    create_table :bulk_actions do |t|
      t.string :action_type
      t.string :status
      t.string :log_name
      t.string :description
      t.integer :druid_count_total, default: 0
      t.integer :druid_count_success, default: 0
      t.integer :druid_count_fail, default: 0

      t.timestamps null: false
      t.belongs_to :user, index: true
    end
  end
end
