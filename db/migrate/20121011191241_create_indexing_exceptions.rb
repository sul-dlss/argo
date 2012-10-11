class CreateIndexingExceptions < ActiveRecord::Migration
  def change
    create_table :indexing_exceptions do |t|
      t.string :pid
      t.text :solr_document
      t.string :dor_services_version
      t.text :exception

      t.timestamps
    end

    add_index :indexing_exceptions, :pid
  end
end
