class BulkAction < ActiveRecord::Base
  UNSTARTED = 'unstarted'.freeze
  PROCESSING = 'processing'.freeze
  FINISHED = 'finished'.freeze

  acts_as_nested_set

  belongs_to :user

  validates :action_type, inclusion: { in: %w(GenericJob DescmetadataDownloadJob ReleaseObjectJob RemoteIndexingJob SetGoverningApoJob) }

  enum(
    status: {
      UNSTARTED => UNSTARTED,
      PROCESSING => PROCESSING,
      FINISHED => FINISHED
    }
  )

  after_create do
    create_output_directory
    create_log_file
    process_bulk_action_type
  end
  before_destroy :remove_output_directory

  # A virtual attribute used for job creation but not persisted
  attr_accessor :manage_release, :set_governing_apo, :webauth
  attr_reader :pids

  def pids=(pids)
    if pids.is_a? String
      @pids = pids.split
    elsif pids.is_a? Enumerable
      @pids = pids
    else
      raise ArgumentError, 'pids must be set to a String that can be split on whitespace, or an Enumerable to be used as-is.'
    end
  end

  def file(filename)
    File.join(output_directory, filename)
  end

  def batch_size
    Settings.BULK_ACTIONS.BATCH_SIZE
  end

  def processing!
    with_lock do
      update_attribute(:druid_count_success, 0)
      update_attribute(:druid_count_fail, 0)
      update_attribute(:status, BulkAction::PROCESSING)
      save!
    end
    parent.rollup_status! if parent.present?
  end

  def finished!
    with_lock do
      update_attribute(:status, BulkAction::FINISHED)
      save!
    end
    parent.rollup_status! if parent.present?
  end

  # this should be called whenever a child of this BulkAction has its status updated, e.g. when it's marked PROCESSING or FINISHED
  def rollup_status!
    rollup_status_from_children!
    parent.rollup_status! if parent.present?
  end

  private

  def rollup_status_from_children!
    # nothing to roll up if there are no children
    return if children.blank?

    with_lock do
      rolled_druid_count_success = children.sum(:druid_count_success)
      rolled_druid_count_fail = children.sum(:druid_count_fail)
      update(status: aggregate_status_of_children, druid_count_success: rolled_druid_count_success, druid_count_fail: rolled_druid_count_fail)
    end
  end

  # note that this only looks at direct children, and so
  # assumes that each child's status is already up-to-date.
  def aggregate_status_of_children
    # .uniq because we only care whether a given status is represented
    # among the children, not how many children have a given status
    child_statuses = children.pluck(:status).uniq

    # only FINISHED or UNSTARTED if all children are in that state, respectively.
    # otherwise, currently PROCESSING.
    return FINISHED if child_statuses == [FINISHED]
    return UNSTARTED if child_statuses == [UNSTARTED]
    PROCESSING
  end

  def prefix
    "#{action_type}_#{id}"
  end

  def output_directory
    File.join(Settings.BULK_METADATA.DIRECTORY, prefix)
  end

  def create_log_file
    log_filename = file(Settings.BULK_METADATA.LOG)
    FileUtils.touch(log_filename)
    update_attribute(:log_name, log_filename)
  end

  def create_output_directory
    FileUtils.mkdir_p(output_directory) unless File.directory?(output_directory)
  end

  def remove_output_directory
    FileUtils.rm_rf(output_directory)
  end

  ##
  # Returns an Array of Hashes of custom params that were sent through on initialization of
  # class, but aren't persisted and need to be passed to the jobs that do the work.
  # The only difference between each hash should be the list of pids to be operated on.  All
  # other field values should be the same across the list.
  # @return [Array<Hash>]
  def batched_job_params_list
    pids.each_slice(batch_size).map do |pid_sublist|
      {
        pids: pid_sublist,
        output_directory: output_directory,
        manage_release: manage_release,
        set_governing_apo: set_governing_apo,
        webauth: webauth
      }
    end
  end

  ##
  # Return an Array of Hashes that can be used to break this BulkAction into a list of child
  # BulkActions, to allow splitting the overall BulkAction into batches that can each be picked up
  # by a worker, to allow more resilience (to errors working on individual objects, to long running
  # batches, etc).
  # @return [Array<Hash>]
  def bulk_action_params_list
    pids.each_slice(batch_size).map do |pid_sublist|
      {
        parent: self,
        pids: pid_sublist,
        action_type: action_type,
        description: description,
        manage_release: manage_release,
        set_governing_apo: set_governing_apo,
        webauth: webauth,
        status: UNSTARTED
      }
    end
  end

  def process_bulk_action_type
    # this should essentially result in one level of recursion in the bulk_action spawning:
    #  * if the pid list has more than batch size elements, break it into child BulkAction objects, each with batch_size or fewer pids.
    #  * otherwise, just spawn a job for each pid.
    update(status: UNSTARTED, druid_count_total: pids.length)
    if pids.length > batch_size
      bulk_action_params_list.each { |bulk_action_params| BulkAction.create!(bulk_action_params) }
    else
      batched_job_params_list.each { |batch_params| action_type.constantize.perform_later(id, batch_params) }
    end
  end
end
