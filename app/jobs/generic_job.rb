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
class GenericJob < ApplicationJob
  # A somewhat easy to understand and informative time stamp format
  TIME_FORMAT = '%Y-%m-%d %H:%M%P'

  attr_reader :druids, :groups

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
    @druids = params[:druids]
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
  def with_bulk_action_log
    BulkJobLog.open(bulk_action.log_name) do |log|
      log.puts("#{Time.current} Starting #{self.class} for BulkAction #{bulk_action.id}")

      yield log

      log.puts("#{Time.current} Finished #{self.class} for BulkAction #{bulk_action.id}")
    end
  end

  ##
  # Loops over the list of druids and loads the cocina item for each. This takes
  # care of incrementing success and fail counts in the job. It also rescues errors
  # and records them as failures.
  # @param [Array<String>] druids the list of identifiers to operate on
  # @param [String] name the name of the operation for logging
  # @yieldparam [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] cocina_object
  # @yieldparam [Proc] success call this with a message if the operation was successful
  # @yieldparam [Proc] failure call this with a message if the operation was unsuccessful
  # @yieldparam [Integer] index
  # @example
  #   with_items(druids, name: 'my operation') do |cocina_object, success, failure|
  #     if operate_on(cocina_object)
  #       success.call("Looks good")
  #     else
  #       failure.call("Something went wrong")
  #     end
  #   end
  def with_items(druids, name:)
    update_druid_count(count: druids.length)
    with_bulk_action_log do |log|
      druids.each_with_index do |druid, idx|
        success = lambda { |message|
          bulk_action.increment(:druid_count_success).save
          log.puts("#{Time.current} #{message} for #{druid}")
        }
        failure = lambda { |message|
          bulk_action.increment(:druid_count_fail).save
          log.puts("#{Time.current} #{message} for #{druid}")
        }

        cocina_object = Dor::Services::Client.object(druid).find
        yield(cocina_object, success, failure, idx)
      rescue StandardError => e
        failure.call("#{name} failed #{e.class} #{e.message}")
        Honeybadger.notify(e, context: { druid: druid })
      end
    end
  end

  def ability
    @ability ||= begin
      user = bulk_action.user
      # Since a user doesn't persist its groups, we need to pass the groups in here.
      user.set_groups_to_impersonate(groups)
      Ability.new(user)
    end
  end

  def update_druid_count(count: druids.length)
    bulk_action.update(druid_count_total: count)
  end

  # @returns [String] the current version
  def open_new_version(druid, version, description)
    wf_status = DorObjectWorkflowStatus.new(druid, version: version)
    raise "#{Time.current} Unable to open new version for #{druid} (bulk_action.id=#{bulk_action.id})" unless wf_status.can_open_version?

    VersionService.open(identifier: druid,
                        significance: 'minor',
                        description: description,
                        opening_user_name: bulk_action.user.to_s)
  end
end
