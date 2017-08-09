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

  before_perform do |_job|
    bulk_action.processing!
  end

  after_perform do |_job|
    bulk_action.finished!
  end

  ##
  # @param [Integer] _bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] _params additional parameters that an Argo job may need
  def perform(_bulk_action_id, _params)
  end

  def bulk_action
    BulkAction.lock.find(arguments[0])
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

  # TODO: switch to using rails logger to write to the log file, so that multiple processes writing to the file gets handled robustly
  def logger
    @logger ||= Logger.new(File.open(bulk_action.log_name, 'a'))
  end
end
