class CreateBulkActionMessages < ActiveRecord::Migration
  def change
    create_table :bulk_action_messages do |t|
      t.string :message
      t.string :druid

      t.timestamps null: false
      t.belongs_to :bulk_action_statuses, index: true
    end
  end
end
