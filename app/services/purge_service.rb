# frozen_string_literal: true

# Removes an object from dor-services-app, the workflow service and solr.
class PurgeService
  # @param [String] druid
  # @param [String] user_name
  def self.purge(druid:, user_name:)
    Dor::Services::Client.object(druid).destroy(user_name:)
    WorkflowClientFactory.build.delete_all_workflows(pid: druid)
    blacklight_config = CatalogController.blacklight_config
    solr_conn = blacklight_config.repository_class.new(blacklight_config).connection
    solr_conn.delete_by_id(druid)
    solr_conn.commit
  end
end
