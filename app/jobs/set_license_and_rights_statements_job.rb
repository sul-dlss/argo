# frozen_string_literal: true

##
# Job to set licenses, copyright statements, and/or use & reproduction statements
class SetLicenseAndRightsStatementsJob < GenericJob
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :pids required list of identifiers
  # @option params [String] :copyright_statement the new copyright statement
  # @option params [String] :copyright_statement_option option to update the copyright statement
  # @option params [String] :license the new license value as a URI
  # @option params [String] :license_option option to update the license value
  # @option params [String] :use_statement the new use statement
  # @option params [String] :use_statement_option option to update the use statement
  def perform(bulk_action_id, params)
    super

    with_bulk_action_log do |log|
      log.puts("#{Time.current} Starting #{self.class} BulkAction #{bulk_action_id}")
      update_druid_count

      args = { ability: ability }.tap do |argument_hash|
        argument_hash[:copyright_statement] = dig_from_params_if_option_set(params, :copyright_statement)
        argument_hash[:license] = dig_from_params_if_option_set(params, :license)
        argument_hash[:use_statement] = dig_from_params_if_option_set(params, :use_statement)
      end.compact

      pids.each do |druid|
        LicenseAndRightsStatementsSetter.set(**args.merge(druid: druid))
        bulk_action.increment(:druid_count_success).save
        log.puts("#{Time.current} License/copyright/use statement(s) updated successfully")
      rescue StandardError => e
        bulk_action.increment(:druid_count_fail).save
        log.puts("#{Time.current} #{self.class} failed for #{druid}: (#{e.class}) #{e.message}")
        Honeybadger.notify(e,
                           context: {
                             bulk_action_id: bulk_action_id,
                             params: params,
                             service_args: args
                           })
      end

      log.puts("#{Time.current} Finished #{self.class} for BulkAction #{bulk_action_id}")
    end
  end

  private

  def dig_from_params_if_option_set(params, key)
    params.dig(:set_license_and_rights_statements, key) if params.dig(:set_license_and_rights_statements, "#{key}_option".to_sym) == '1'
  end
end
