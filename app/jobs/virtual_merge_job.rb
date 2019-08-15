# frozen_string_literal: true

##
# job to merge objects
class VirtualMergeJob < GenericJob
  queue_as :default

  def perform(_bulk_action_id, parent_druid:, child_druids:)
    client = Dor::Services::Client.object(parent_druid)
    client.add_constituents(child_druids: child_druids)
    ([parent_druid] + child_druids).each do |druid|
      close(druid)
    end
  end

  private

  def close(druid)
    object_client = Dor::Services::Client.object(druid)
    object_client.version.close
  end
end
