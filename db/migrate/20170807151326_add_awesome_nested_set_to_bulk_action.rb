class AddAwesomeNestedSetToBulkAction < ActiveRecord::Migration[5.1]
  def self.up
    add_column :bulk_actions, :parent_id, :integer, :null => true, :index => true
    add_column :bulk_actions, :lft, :integer, :index => true
    add_column :bulk_actions, :rgt, :integer, :index => true

    # awesome_nested_set wants lft and rgt cols to be NOT NULL, but sqlite complains about the
    # migration if the NOT NULL constraint is declared when the column is added:
    #  ActiveRecord::StatementInvalid: SQLite3::SQLException:
    #  Cannot add a NOT NULL column with default value NULL: ALTER TABLE "bulk_actions" ADD "lft" integer NOT NULL
    # but it's fine with adding the constraint once the column's there, so add it after the fact.
    # https://stackoverflow.com/a/6710280
    change_column :bulk_actions, :lft, :integer, :null => false
    change_column :bulk_actions, :rgt, :integer, :null => false

    BulkAction.rebuild!
  end

  def self.down
    remove_column :categories, :parent_id
    remove_column :categories, :lft
    remove_column :categories, :rgt
  end
end
