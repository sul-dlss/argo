class CreateRobots < ActiveRecord::Migration
  def change
    create_table :robots do |t|
      t.string :wf
      t.string :process
      t.timestamps
    end
  end
end
