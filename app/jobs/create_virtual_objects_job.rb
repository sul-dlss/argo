# frozen_string_literal: true

##
# job to create batches of virtual objects
class CreateVirtualObjectsJob < GenericJob
  queue_as :default

  # we don't want to retry these jobs -- too messy
  def max_attempts
    1
  end

  # big merges may run ridiculously long
  def max_run_time
    96.hours
  end

  NOT_COMBINABLE_MESSAGE = 'Creating some or all virtual objects failed because some objects are not combinable'
  NOT_FOUND_MESSAGE = 'Could not create virtual objects because the following parent druids were not found'
  SUCCESS_MESSAGE = 'Successfully created virtual objects'
  UNAUTHORIZED_MESSAGE = 'Could not create virtual objects because user lacks ability to manage the following parent druids'

  ##
  # A job that creates virtual objects
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [String] :create_virtual_objects CSV string
  def perform(bulk_action_id, params)
    super

    virtual_objects = VirtualObjectsCsvConverter.convert(csv_string: params[:create_virtual_objects])

    with_bulk_action_log do |log|
      log.puts("#{Time.current} Starting #{self.class} for BulkAction #{bulk_action_id}")

      # NOTE: We use this instead of `update_druid_count` because virtual object
      #       creation does not use the `pids` form field.
      bulk_action.update(druid_count_total: virtual_objects.length)

      # NOTE: `ability` is defined in this job's superclass, `GenericJob`
      not_found_druids, unauthorized_druids = ProblematicDruidFinder.find(druids: parent_ids_from(virtual_objects), ability: ability)
      problematic_druids = not_found_druids + unauthorized_druids

      if problematic_druids.any?
        log.puts("#{Time.current} #{UNAUTHORIZED_MESSAGE}: #{unauthorized_druids.to_sentence}") if unauthorized_druids.any?
        log.puts("#{Time.current} #{NOT_FOUND_MESSAGE}: #{not_found_druids.to_sentence}") if not_found_druids.any?
        bulk_action.increment!(:druid_count_fail, problematic_druids.length)

        # Short-circuit if all parent druids were problematic
        if problematic_druids.length == virtual_objects.length
          log.puts("#{Time.current} No virtual objects could be created. See other log entries for more detail.")
          log.puts("#{Time.current} Finished #{self.class} for BulkAction #{bulk_action_id}")
          return
        end

        # Only *some* parent druids were problematic, so remove them from the list of objects to be operated upon
        virtual_objects.reject! { |virtual_object| problematic_druids.include?(virtual_object[:parent_id]) }
      end

      errors = VirtualObjectsCreator.create(virtual_objects: virtual_objects)
      ActiveRecord::Base.clear_active_connections!
      if errors.empty?
        bulk_action.increment!(:druid_count_success, virtual_objects.length)
        log.puts("#{Time.current} #{SUCCESS_MESSAGE}: #{parent_ids_from(virtual_objects).to_sentence}")
      else
        bulk_action.increment!(:druid_count_success, virtual_objects.length - errors.length)
        bulk_action.increment!(:druid_count_fail, errors.length)
        log.puts("#{Time.current} #{NOT_COMBINABLE_MESSAGE}: #{errors.join('; ')}")
      end

      log.puts("#{Time.current} Finished #{self.class} for BulkAction #{bulk_action_id}")
    end
  end

  private

  def parent_ids_from(virtual_objects)
    virtual_objects.map { |hash| hash[:parent_id] }
  end
end
