##
# A GenericJob used as a super class for Argo Bulk Jobs
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
end
