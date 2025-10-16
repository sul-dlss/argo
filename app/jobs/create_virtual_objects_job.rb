# frozen_string_literal: true

##
# job to create batches of virtual objects
class CreateVirtualObjectsJob < BulkActionJob
  NOT_COMBINABLE_MESSAGE = 'Creating some or all virtual objects failed because some objects are not combinable'
  NOT_FOUND_MESSAGE = 'Could not create virtual objects because the following virtual object druids were not found'
  SUCCESS_MESSAGE = 'Successfully created virtual objects'
  UNAUTHORIZED_MESSAGE = 'Could not create virtual objects because user lacks ability to manage the following virtual object druids'

  def perform_bulk_action
    return unless check_virtual_objects?

    errors = VirtualObjectsCreator.create(virtual_objects:)
    # line below was added Jan 2020 because on very long running jobs, rails would drop the database connectinon and throw an exception instead of auto-reconnecting
    #   this would cause the entire job to fail (even though it may have actually completed), which would trigger another run of the job
    ActiveRecord::Base.connection_handler.clear_active_connections!
    if errors.empty?
      bulk_action.increment!(:druid_count_success, virtual_objects.length)
      log("#{SUCCESS_MESSAGE}: #{virtual_object_druids.to_sentence}")
    else
      bulk_action.increment!(:druid_count_success, virtual_objects.length - errors.length)
      bulk_action.increment!(:druid_count_fail, errors.length)
      log("#{NOT_COMBINABLE_MESSAGE}: #{errors.join('; ')}")
    end
  end

  def virtual_objects
    @virtual_objects ||= VirtualObjectsCsvConverter.convert(csv_string: params[:csv_file])
  end

  def druid_count
    virtual_objects.length
  end

  def virtual_object_druids
    virtual_objects.pluck(:virtual_object_id)
  end

  def check_virtual_objects?
    not_found_druids, unauthorized_druids = ProblematicDruidFinder.find(
      druids: virtual_object_druids, ability:
    )
    problematic_druids = not_found_druids + unauthorized_druids

    return true if problematic_druids.empty?

    if unauthorized_druids.any?
      log("#{UNAUTHORIZED_MESSAGE}: #{unauthorized_druids.to_sentence}")
    end
    log("#{NOT_FOUND_MESSAGE}: #{not_found_druids.to_sentence}") if not_found_druids.any?
    bulk_action.increment!(:druid_count_fail, problematic_druids.length)

    # Short-circuit if all virtual object druids were problematic
    if problematic_druids.length == virtual_objects.length
      log('No virtual objects could be created. See other log entries for more detail.')
      return false
    end

    # Only *some* virtual object druids were problematic, so remove them from the list of objects to be operated upon
    virtual_objects.reject! { |virtual_object| problematic_druids.include?(virtual_object[:virtual_object_id]) }
    true
  end
end
