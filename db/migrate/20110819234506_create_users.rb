class CreateUsers < ActiveRecord::Migration[4.2]
  def self.up
    create_table :users do |t|
      t.string :sunetid
      t.timestamps
    end
  end

  def self.down
    drop_table :users
  end
end
