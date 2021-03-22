# frozen_string_literal: true

# Removes an object from dor-services-app, the workflow service and solr.
class PurgeService
  def self.purge(druid:)
    Dor::Services::Client.object(druid).destroy
    WorkflowClientFactory.build.delete_all_workflows(pid: druid)
    blacklight_config = CatalogController.blacklight_config
    solr_conn = blacklight_config.repository_class.new(blacklight_config).connection
    solr_conn.delete_by_id(druid)
    solr_conn.commit
  end
end
