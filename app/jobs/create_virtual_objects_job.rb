# frozen_string_literal: true

##
# job to create virtual objects
class CreateVirtualObjectsJob < GenericJob
  queue_as :default

  NOT_COMBINABLE_MESSAGE = 'Creating some or all virtual objects failed because some objects are not combinable'
  NOT_FOUND_MESSAGE = 'Could not create virtual objects because the following parent druids were not found'
  SUCCESS_MESSAGE = 'Successfully created virtual objects'
  TIMEOUT_MESSAGE = 'Virtual object creation timed out'
  UNAUTHORIZED_MESSAGE = 'Could not create virtual objects because user lacks ability to manage the following parent druids'
  UNEXPECTED_MESSAGE = 'Terminating. An unexpected error occurred creating the batch of virtual objects'

  ##
  # A job that creates virtual objects
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [String] :create_virtual_objects CSV string
  def perform(bulk_action_id, params)
    super

    virtual_objects = VirtualObjectsCsvConverter.convert(csv_string: params[:create_virtual_objects])

    # rubocop:disable Metrics/BlockLength
    with_bulk_action_log do |log|
      log.puts("#{Time.current} Starting #{self.class} for BulkAction #{bulk_action_id}")

      parent_druids = parent_ids_from(virtual_objects)

      # NOTE: We use this instead of `update_druid_count` because virtual object
      #       creation does not use the `pids` form field.
      bulk_action.update(druid_count_total: parent_druids.length)

      problematic_druids = find_problematic_druids(parent_druids)

      if problematic_druids.values.flatten.any?
        log.puts("#{Time.current} #{UNAUTHORIZED_MESSAGE}: #{problematic_druids[:unauthorized].to_sentence}") if problematic_druids[:unauthorized].any?
        log.puts("#{Time.current} #{NOT_FOUND_MESSAGE}: #{problematic_druids[:not_found].to_sentence}") if problematic_druids[:not_found].any?
        bulk_action.increment!(:druid_count_fail, problematic_druids.values.flatten.length)
        # Remove problematic parent druids from list of objects to be operated upon
        virtual_objects[:virtual_objects].reject! do |virtual_object|
          problematic_druids.values.flatten.include?(virtual_object[:parent_id])
        end
        return if virtual_objects.values.flatten.empty?
      end

      begin
        Dor::Services::Client.virtual_objects.create(virtual_objects)
        bulk_action.increment!(:druid_count_success, virtual_objects[:virtual_objects].length)
        log.puts("#{Time.current} #{SUCCESS_MESSAGE}: #{parent_ids_from(virtual_objects).to_sentence}")
      rescue Faraday::TimeoutError
        bulk_action.increment!(:druid_count_fail, virtual_objects[:virtual_objects].length)
        total_druids = virtual_objects[:virtual_objects].map(&:values).flatten.length
        log.puts("#{Time.current} #{TIMEOUT_MESSAGE}, given #{total_druids} druids in the batch.")
        Honeybadger.notify("#{TIMEOUT_MESSAGE}, given #{total_druids}, druids in the batch.")
      rescue Dor::Services::Client::UnexpectedResponse => e
        errors = errors_from(e.message)

        # Some exceptions are more unexpected than others
        if errors.respond_to?(:map) && errors.all? { |error| error.is_a?(Hash) }
          errors.map do |error|
            "Problem children for #{error.keys.first}: #{error.values.flatten.to_sentence}"
          end
          bulk_action.increment!(:druid_count_success, virtual_objects.length - errors.length)
          bulk_action.increment!(:druid_count_fail, errors.length)
          log.puts("#{Time.current} #{NOT_COMBINABLE_MESSAGE}: #{errors.join('; ')}")
        else
          Honeybadger.notify("Unexpected Dor::Services::Client error creating virtual objects: #{e.message}")
          log.puts("#{Time.current} #{UNEXPECTED_MESSAGE}: #{e.message}. \
                   An alert has been sent. Success/fail counts for this batch will be off.")
        end
      end

      log.puts("#{Time.current} Finished #{self.class} for BulkAction #{bulk_action_id}")
    end
    # rubocop:enable Metrics/BlockLength
  end

  private

  def find_problematic_druids(druids)
    problematic_druids = {
      unauthorized: [],
      not_found: []
    }

    druids.each do |druid|
      current_obj = Dor.find(druid)
      problematic_druids[:unauthorized] << druid unless ability.can?(:manage_item, current_obj)
    rescue ActiveFedora::ObjectNotFoundError
      problematic_druids[:not_found] << druid
    end

    problematic_druids
  end

  def parent_ids_from(virtual_objects)
    virtual_objects[:virtual_objects].map { |hash| hash[:parent_id] }
  end

  def errors_from(error_string)
    matches = error_string.match(/(?<status_text>\w+): (?<status_code>\d+) \((?<error_json>.+)\)/)
    JSON.parse(matches[:error_json])['errors']
  end
end
