class BulkAction < ActiveRecord::Base
  belongs_to :user
  after_create :process_bulk_action_type

  # A virtual attribute used for job creation but not persisted
  attr_accessor :pids

  private

  ##
  # Returns a has of custom params that were sent through on initialization of
  # class, but aren't persisted and need to be passed to job.
  # @return [Hash]
  def job_params
    {
      pids: pids.split
    }
  end

  def process_bulk_action_type
    action_type.constantize.perform_later(job_params[:pids], id, 'tmp/')
    update_attribute(:status, 'Scheduled Action')
  end
end
