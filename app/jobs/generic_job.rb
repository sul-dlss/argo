##
# A GenericJob used as a super class for Argo Bulk Jobs
#
# IMPORTANT NOTE: actions performed under this job framework should probably be idempotent
# with respect to any given DOR object being operated on:
#  "the property of certain operations in mathematics and computer science, that can be applied
#  multiple times without changing the result beyond the initial application."
#  - https://en.wikipedia.org/wiki/Idempotence
#
# because, if a job fails, it gets re-run, and if that job had been partially successful, some
# objects in the batch might undergo the same action more than once.
class GenericJob < ActiveJob::Base
  # A somewhat easy to understand and informative time stamp format
  TIME_FORMAT = '%Y-%m-%d %H:%M%P'.freeze

  around_perform do |_job, block|
    bulk_action.update_attribute(:status, 'Processing')
    block.call
    bulk_action.update_attribute(:status, 'Completed')
  end

  ##
  # @param [Integer] _a GlobalID for a BulkAction object
  # @param [Hash] _b additional parameters that an Argo job may need
  def perform(_a, _b)
  end

  def bulk_action
    @bulk_action ||= BulkAction.find(arguments[0])
  end

  # usage:
  # with_bulk_action_log do |log_buf|
  #   log_buf.puts 'something happening with this bulk action'
  #   # do some stuff
  #   log_buf.puts 'another thing about the state of this bulk action'
  # end
  def with_bulk_action_log
    File.open(bulk_action.log_name, 'a') do |log_buffer|
      yield(log_buffer)
    end
  end
end
