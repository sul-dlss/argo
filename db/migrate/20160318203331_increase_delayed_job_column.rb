class IncreaseDelayedJobColumn < ActiveRecord::Migration[4.2]
  def change
    # This migration was created when Argo ran on MySQL (in prod) and sqlite (in
    # other envs). The :text datatype in Postgres is unlimited, so this is a
    # no-op now. Left the former migration commented out for posterity.
    #
    #
    # Ensure that the handler column in the delayed_job table is MySQL longtext
    # so that we can pass in lots of druids in the params when a new Delayed
    # Job is created.
    # change_column :delayed_jobs, :handler, :text, limit: 4_294_967_295
  end
end
