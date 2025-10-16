# frozen_string_literal: true

# A super class for bulk jobs
#
# IMPORTANT NOTE: actions performed under this job framework should probably be idempotent
# with respect to any given DOR object being operated on:
#  "the property of certain operations in mathematics and computer science, that can be applied
#  multiple times without changing the result beyond the initial application."
#  - https://en.wikipedia.org/wiki/Idempotence
#
# because, if a job fails, it gets re-run, and if that job had been partially successful, some
# objects in the batch might undergo the same action more than once.
class BulkActionJob < ApplicationJob
  attr_reader :params, :bulk_action

  # @param [Integer] bulk_action_id id for a BulkAction object
  # @param [Hash] params additional parameters
  def perform(bulk_action_id, params)
    @bulk_action ||= BulkAction.find(bulk_action_id)
    @params = params
    Honeybadger.context(bulk_action_id:, params:)

    bulk_action.reset_druid_counts

    bulk_action.update(status: 'Processing')

    log("Starting #{self.class} for BulkAction #{bulk_action.id}")
    update_druid_count!
    FileUtils.mkdir_p(bulk_action.output_directory)

    perform_bulk_action

    log("Finished #{self.class} for BulkAction #{bulk_action.id}")
    bulk_action.update(status: 'Completed')
  ensure
    export_file&.close
    log_file&.close
  end

  # Invokes a bulk action item for each druid
  # Each bulk action job class should implement a nested class called BulkActionItem
  # that is a subclass of BulkActionItem.
  def perform_bulk_action
    druids.each_with_index do |druid, index|
      perform_item_class.new(druid:, index:, job: self).perform
    rescue StandardError => e
      failure!(druid: druid, message: "Failed #{e.class} #{e.message}")
      Honeybadger.notify(e)
    end
  end

  def ability
    @ability ||= begin
      user = bulk_action.user
      # Since a user doesn't persist its groups, we need to pass the groups in here.
      user.set_groups_to_impersonate(params[:groups])
      Ability.new(user)
    end
  end

  def update_druid_count!
    bulk_action.update(druid_count_total: druid_count)
  end

  def user
    bulk_action.user.to_s
  end

  def log(message)
    log_file.puts("#{Time.zone.now} #{message}")
  end

  def druids
    params[:druids]
  end

  def druid_count
    druids.length
  end

  def perform_item_class
    # For example, the bulk action item for AddWorkflowJob is AddWorkflowJob::AddWorkflowJobItem
    "#{self.class}::#{self.class.name.sub('Job', 'JobItem')}".constantize
  end

  # Open file to use for export output, if any.
  # By default, there is no export file.
  # It will be closed automatically when the job ends and available to BulkActionItem.
  # For example: @export_file ||= CSV.open(csv_download_path, 'w', write_headers: true, headers: HEADERS)
  def export_file
    @export_file ||= nil
  end

  def success!(druid:, message: nil)
    bulk_action.increment(:druid_count_success)
    log("#{message} for #{druid}") if message
  end

  def failure!(druid:, message:)
    bulk_action.increment(:druid_count_fail)
    log("#{message} for #{druid}")
  end

  def check_view_ability?
    return true if ability.can?(:view, Cocina::Models::DRO)

    log('Not authorized to view all content')
    bulk_action.increment(:druid_count_fail, druid_count).save

    false
  end

  private

  def log_file
    @log_file ||= bulk_action.open_log_file
  end
end
