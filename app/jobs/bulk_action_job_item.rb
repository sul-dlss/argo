# frozen_string_literal: true

# Super class for performing an action on a single item in a BulkActionJob.
# Subclasses must implement the perform method.
class BulkActionJobItem
  def initialize(druid:, index:, job:)
    @druid = druid
    @index = index
    @job = job
    Honeybadger.context(druid:)
  end

  delegate :log, :user, :ability, :export_file, :close_version?, to: :job

  attr_reader :druid, :index, :job

  # Perform the action on the item.
  # Subclasses should call success! or failure! as appropriate.
  # They may also call any of the other helper methods defined below.
  def perform
    raise NotImplementedError, 'Subclasses must implement perform'
  end

  # Indicate that the action was successful.
  def success!(message: nil)
    job.success!(druid: druid, message: message)
  end

  # Indicate that the action failed.
  def failure!(message:)
    job.failure!(druid: druid, message: message)
  end

  def cocina_object
    @cocina_object ||= Repository.find(druid)
  end

  def open_new_version_if_needed!(description:)
    return if VersionService.open?(druid:)
    raise 'Unable to open new version' unless VersionService.openable?(druid:)

    @cocina_object = VersionService.open(druid:, description:, opening_user_name: user)
    log("Opened new version (#{description})")
  end

  def close_version_if_needed!
    # Do not close version unless requested to by user (via a job parameter)
    return unless close_version?

    # Do not close the initial version of an object
    return if cocina_object.version == 1

    return log('Version already closed') if VersionService.closed?(druid:)

    raise 'Unable to close version' unless VersionService.closeable?(druid:)

    VersionService.close(druid:)
    log('Closed version')
  end

  def check_update_ability?
    return true if ability.can?(:update, cocina_object)

    failure!(message: 'Not authorized to update')
    false
  end

  def check_read_ability?
    return true if ability.can?(:read, cocina_object)

    failure!(message: 'Not authorized to read')
    false
  end
end
