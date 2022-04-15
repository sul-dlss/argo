# frozen_string_literal: true

##
# job to create batches of virtual objects
class CreateVirtualObjectsJob < GenericJob
  # we don't want to retry these jobs -- too messy
  def max_attempts
    1
  end

  # big merges may run ridiculously long
  def max_run_time
    96.hours
  end

  NOT_COMBINABLE_MESSAGE = 'Creating some or all virtual objects failed because some objects are not combinable'
  NOT_FOUND_MESSAGE = 'Could not create virtual objects because the following virtual object druids were not found'
  SUCCESS_MESSAGE = 'Successfully created virtual objects'
  UNAUTHORIZED_MESSAGE = 'Could not create virtual objects because user lacks ability to manage the following virtual object druids'

  ##
  # A job that creates virtual objects
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [String] :csv_file CSV string
  def perform(bulk_action_id, params)
    super

    virtual_objects = VirtualObjectsCsvConverter.convert(csv_string: params[:csv_file])

    with_bulk_action_log do |log|
      update_druid_count(count: virtual_objects.length)

      # NOTE: `ability` is defined in this job's superclass, `GenericJob`
      not_found_druids, unauthorized_druids = ProblematicDruidFinder.find(druids: virtual_object_ids_from(virtual_objects), ability:)
      problematic_druids = not_found_druids + unauthorized_druids

      if problematic_druids.any?
        log.puts("#{Time.current} #{UNAUTHORIZED_MESSAGE}: #{unauthorized_druids.to_sentence}") if unauthorized_druids.any?
        log.puts("#{Time.current} #{NOT_FOUND_MESSAGE}: #{not_found_druids.to_sentence}") if not_found_druids.any?
        bulk_action.increment!(:druid_count_fail, problematic_druids.length)

        # Short-circuit if all virtual object druids were problematic
        if problematic_druids.length == virtual_objects.length
          log.puts("#{Time.current} No virtual objects could be created. See other log entries for more detail.")
          log.puts("#{Time.current} Finished #{self.class} for BulkAction #{bulk_action_id}")
          return
        end

        # Only *some* virtual object druids were problematic, so remove them from the list of objects to be operated upon
        virtual_objects.reject! { |virtual_object| problematic_druids.include?(virtual_object[:virtual_object_id]) }
      end

      errors = VirtualObjectsCreator.create(virtual_objects:)
      # line below was added Jan 2020 because on very long running jobs, rails would drop the database connectinon and throw an exception instead of auto-reconnecting
      #   this would cause the entire job to fail (even though it may have actually completed), which would trigger another run of the job
      ActiveRecord::Base.clear_active_connections!
      if errors.empty?
        bulk_action.increment!(:druid_count_success, virtual_objects.length)
        log.puts("#{Time.current} #{SUCCESS_MESSAGE}: #{virtual_object_ids_from(virtual_objects).to_sentence}")
      else
        bulk_action.increment!(:druid_count_success, virtual_objects.length - errors.length)
        bulk_action.increment!(:druid_count_fail, errors.length)
        log.puts("#{Time.current} #{NOT_COMBINABLE_MESSAGE}: #{errors.join('; ')}")
      end
    end
  end

  private

  def virtual_object_ids_from(virtual_objects)
    virtual_objects.map { |hash| hash[:virtual_object_id] }
  end
end
