# frozen_string_literal: true

##
# job to merge objects
class VirtualMergeJob < GenericJob
  queue_as :default

  def perform(_bulk_action_id, parent_druid:, child_druids:)
    client = Dor::Services::Client.object(parent_druid)
    client.add_constituents(child_druids: child_druids)
    ([parent_druid] + child_druids).each do |druid|
      VersionService.close(identifier: druid)
    end
  end
end
