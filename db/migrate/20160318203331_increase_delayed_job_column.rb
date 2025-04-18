class IncreaseDelayedJobColumn < ActiveRecord::Migration[4.2]
  def change
    # Only run this migration if MySQL is the database. The :text datatype in Postgres is unlimited.
    if ActiveRecord::Base.connection.adapter_name.match?(/mysql/i)
      # Ensure that the handler column in the delayed_job table is MySQL longtext
      # so that we can pass in lots of druids in the params when a new Delayed
      # Job is created.
      change_column :delayed_jobs, :handler, :text, limit: 4_294_967_295
    end
  end
end
