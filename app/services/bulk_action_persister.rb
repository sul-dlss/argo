# frozen_string_literal: true

class BulkActionPersister
  def self.persist(bulk_action_form)
    new(bulk_action_form).persist
  end

  def initialize(bulk_action_form)
    @bulk_action_form = bulk_action_form
  end

  def persist
    return unless bulk_action.save

    create_output_directory
    create_log_file
    process_bulk_action_type
    true
  end

  private

  attr_reader :bulk_action_form

  delegate :pids, :manage_release, :set_governing_apo,
           :manage_catkeys, :groups, :prepare, :create_virtual_objects,
           :import_tags, to: :bulk_action_form

  delegate :id, :file, :output_directory, to: :bulk_action

  def bulk_action
    bulk_action_form.model
  end

  def create_log_file
    log_filename = file(Settings.bulk_metadata.log)
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
      pids: pids.split,
      manage_release: manage_release,
      set_governing_apo: set_governing_apo,
      manage_catkeys: manage_catkeys,
      prepare: prepare,
      create_virtual_objects: csv_from_file(create_virtual_objects),
      import_tags: csv_from_file(import_tags),
      groups: groups
    }
  end

  def csv_from_file(params)
    # Short-circuit if request is not related to creating virtual objects
    return if params.nil? || params[:csv_file].nil?

    File.read(params[:csv_file].path)
  end
end
