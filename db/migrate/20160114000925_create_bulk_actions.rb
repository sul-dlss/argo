class CreateBulkActions < ActiveRecord::Migration
  def change
    create_table :bulk_actions do |t|
      t.string :action_type
      t.string :status
      t.string :log_name
      t.string :description
      t.integer :druid_count_total
      t.integer :druid_count_success
      t.integer :druid_count_fail

      t.timestamps null: false
      t.belongs_to :user, index: true
    end
  end
end
