class CreateBulkDescmetadataDownloads < ActiveRecord::Migration
  def change
    create_table :bulk_descmetadata_downloads do |t|
      t.string :filename

      t.timestamps null: false
    end
  end
end
