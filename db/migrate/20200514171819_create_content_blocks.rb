class CreateContentBlocks < ActiveRecord::Migration[5.2]
  def change
    create_table :content_blocks do |t|
      t.text :value, null: false
      t.datetime :start_at, null: false
      t.datetime :end_at, null: false
      t.integer :ordinal, null: false

      t.timestamps
    end
  end
end
