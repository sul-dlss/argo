class DropWfsRailsWorkflows < ActiveRecord::Migration[5.1]
  def change
    # This migration was created by a gem that was only loaded in development and
    # test modes. So, dropping the table in production/staging would fail.
    # Additionally, the drop_table would fail for anyone who has newly created
    # their database and had never had the wfs_rails gem installed
    return unless ActiveRecord::Base.connection.table_exists? 'wfs_rails_workflows'
    drop_table :wfs_rails_workflows
  end
end
