# frozen_string_literal: true

##
# Job to set licenses, copyright statements, and/or use & reproduction statements
class SetLicenseAndRightsStatementsJob < GenericJob
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :druids required list of identifiers
  # @option params [String] :copyright_statement the new copyright statement
  # @option params [String] :copyright_statement_option option to update the copyright statement
  # @option params [String] :license the new license value as a URI
  # @option params [String] :license_option option to update the license value
  # @option params [String] :use_statement the new use statement
  # @option params [String] :use_statement_option option to update the use statement
  def perform(bulk_action_id, params)
    super

    args = {}.tap do |argument_hash|
      argument_hash[:copyright] = dig_from_params_if_option_set(params, :copyright_statement)
      argument_hash[:license] = dig_from_params_if_option_set(params, :license)
      argument_hash[:use_statement] = dig_from_params_if_option_set(params, :use_statement)
    end.compact

    with_items(params[:druids], name: "Set license and rights statement") do |cocina_object, success, failure|
      next failure.call("Not authorized") unless ability.can?(:update, cocina_object)
      next failure.call("Not an item or collection (#{cocina_object.type})") unless cocina_object.dro? || cocina_object.collection?

      klass = change_set_class(cocina_object)
      change_set = klass.new(cocina_object)
      change_set.validate(args)

      next success.call("No changes made") unless change_set.changed?

      updated_object = open_new_version_if_needed(cocina_object,
        "updated license, copyright statement, and/or use and reproduction statement")

      change_set = klass.new(updated_object)
      change_set.validate(args)
      change_set.save

      success.call("License/copyright/use statement(s) updated successfully")
    end
  end

  private

  def change_set_class(cocina_object)
    case cocina_object
    when Cocina::Models::DROWithMetadata
      ItemChangeSet
    when Cocina::Models::CollectionWithMetadata
      CollectionChangeSet
    end
  end

  def dig_from_params_if_option_set(params, key)
    params.fetch(key) if params["#{key}_option"] == "1"
  end
end
