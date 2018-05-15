class DropWfsRailsWorkflows < ActiveRecord::Migration[5.1]
  def change
    drop_table :wfs_rails_workflows
  end
end
