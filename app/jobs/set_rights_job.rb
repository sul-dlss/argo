# frozen_string_literal: true

##
# Job to update rights for objects
class SetRightsJob < BulkActionJob
  def access_params
    @access_params ||= params.slice(:view_access, :download_access, :controlled_digital_lending, :access_location)
  end

  def perform_bulk_action
    raise 'Must provide rights' if access_params.blank?

    super
  end

  class SetRightsJobItem < BulkActionJobItem
    delegate :access_params, to: :job

    def perform
      return unless check_update_ability?

      open_new_version_if_needed!(description: 'Updated rights')

      change_set.validate(**new_access_params)
      change_set.save
      close_version_if_needed!

      success!(message: 'Successfully updated rights')
    end

    def new_access_params
      return access_params unless cocina_object.collection?

      # Collection only allows setting view access to dark or world
      view_access = access_params[:view_access] == 'dark' ? 'dark' : 'world'
      { view_access: }
    end

    private

    def change_set
      @change_set ||= (cocina_object.collection? ? CollectionChangeSet : ItemChangeSet).new(cocina_object)
    end
  end
end
