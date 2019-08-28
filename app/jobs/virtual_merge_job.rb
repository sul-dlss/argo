# frozen_string_literal: true

##
# job to merge objects and then close the version
class VirtualMergeJob < GenericJob
  queue_as :default

  def perform(_bulk_action_id, parent_druid:, child_druids:)
    return unless authorized_to_manage?(parent_druid)

    client = Dor::Services::Client.object(parent_druid)
    client.add_constituents(child_druids: child_druids)

    ([parent_druid] + child_druids).each do |druid|
      VersionService.close(identifier: druid)
    end
  end

  private

  def authorized_to_manage?(druid)
    current_obj = Dor.find(druid)
    return true if ability.can?(:manage_item, current_obj)

    false
  end
end
