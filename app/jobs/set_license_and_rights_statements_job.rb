# frozen_string_literal: true

##
# Job to set licenses, copyright statements, and/or use & reproduction statements
class SetLicenseAndRightsStatementsJob < BulkActionJob
  def args
    @args ||= {}.tap do |argument_hash|
      argument_hash[:copyright] = dig_from_params_if_option_set(params, :copyright_statement)
      argument_hash[:license] = dig_from_params_if_option_set(params, :license)
      argument_hash[:use_statement] = dig_from_params_if_option_set(params, :use_statement)
    end.compact
  end

  class SetLicenseAndRightsStatementsJobItem < BulkActionJobItem
    delegate :args, to: :job
    attr_reader :change_set

    def perform
      return unless check_update_ability?

      return failure!(message: "Not an item or collection (#{cocina_object.type})") unless cocina_object.dro? || cocina_object.collection?

      @change_set = build_change_set

      return success!(message: 'No changes made') unless change_set.changed?

      open_new_version_if_needed!(description: 'Updated license, copyright statement, and/or use and reproduction statement')

      # cocina object may have changed; re-instantiate the change set
      @change_set = build_change_set
      change_set.save
      close_version_if_needed!

      success!(message: 'License/copyright/use statement(s) updated successfully')
    end

    private

    def change_set_class
      cocina_object.collection? ? CollectionChangeSet : ItemChangeSet
    end

    def build_change_set
      change_set_class.new(cocina_object).tap do |change_set|
        change_set.validate(args)
      end
    end
  end

  private

  def dig_from_params_if_option_set(params, key)
    params.fetch(key) if params["#{key}_option"] == '1'
  end
end
