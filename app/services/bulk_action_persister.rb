# frozen_string_literal: true

class BulkActionPersister
  def self.persist(bulk_action)
    new(bulk_action).persist
  end

  def initialize(bulk_action)
    @bulk_action = bulk_action
  end

  def persist
    return unless bulk_action.save

    create_output_directory
    create_log_file
    process_bulk_action_type
    true
  end

  private

  attr_reader :bulk_action
  delegate :id, :file, :pids, :output_directory, :manage_release, :set_governing_apo,
           :manage_catkeys, :groups, :prepare, :create_virtual_object, to: :bulk_action

  def create_log_file
    log_filename = file(Settings.BULK_METADATA.LOG)
    FileUtils.touch(log_filename)
    bulk_action.update(log_name: log_filename)
  end

  def create_output_directory
    FileUtils.mkdir_p(output_directory) unless File.directory?(output_directory)
  end

  def process_bulk_action_type
    active_job_class.perform_later(id, job_params)
    bulk_action.update(status: 'Scheduled Action')
  end

  def active_job_class
    bulk_action.action_type.constantize
  end

  ##
  # Returns a Hash of custom params that were sent through on initialization of
  # class, but aren't persisted and need to be passed to job.
  # @return [Hash]
  def job_params
    {
      pids: pids,
      output_directory: output_directory,
      manage_release: manage_release,
      set_governing_apo: set_governing_apo,
      manage_catkeys: manage_catkeys,
      prepare: prepare,
      create_virtual_object: create_virtual_object,
      groups: groups
    }
  end
end
