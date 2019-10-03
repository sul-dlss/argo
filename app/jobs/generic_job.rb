# frozen_string_literal: true

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
  TIME_FORMAT = '%Y-%m-%d %H:%M%P'

  attr_reader :pids, :groups

  before_perform do |_job|
    bulk_action.reset_druid_counts
  end

  around_perform do |_job, block|
    bulk_action.update_attribute(:status, 'Processing')
    block.call
    bulk_action.update_attribute(:status, 'Completed')
  end

  ##
  # @param [Integer] _bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  def perform(_bulk_action_id, params)
    @groups = params[:groups]
    @pids = params[:pids]
    @current_user = bulk_action.user
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
  def with_bulk_action_log(&block)
    File.open(bulk_action.log_name, 'a', &block)
  end

  def ability
    @ability ||= begin
      user = bulk_action.user
      # Since a user doesn't persist its groups, we need to pass the groups in here.
      user.set_groups_to_impersonate(groups)
      Ability.new(user)
    end
  end

  def string_to_boolean(string)
    case string
    when 'true'
      true
    when 'false'
      false
    end
  end

  def update_druid_count
    bulk_action.update(druid_count_total: pids.length)
  end

  def open_new_version(object, description)
    raise "#{Time.current} Unable to open new version for #{object.pid} (bulk_action.id=#{bulk_action.id})" unless DorObjectWorkflowStatus.new(object.pid).can_open_version?

    VersionService.open(identifier: object.pid,
                        significance: 'minor',
                        description: description,
                        opening_user_name: bulk_action.user.to_s)
  end
end
