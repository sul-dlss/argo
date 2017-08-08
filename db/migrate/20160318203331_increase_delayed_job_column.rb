class IncreaseDelayedJobColumn < ActiveRecord::Migration[4.2]
  def change
    # Ensure that the handler column in the delayed_job table is MySQL longtext
    # so that we can pass in lots of druids in the params when a new Delayed
    # Job is created.
    change_column :delayed_jobs, :handler, :text, :limit => 4294967295
  end
end
