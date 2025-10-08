# frozen_string_literal: true

##
# job to reindex a DOR object to Solr using the dor_indexing_app endpoint
class RemoteIndexingJob < BulkActionJob
  class RemoteIndexingJobItem < BulkActionJobItem
    def perform
      Dor::Services::Client.object(druid).reindex
      success!(message: 'Reindex successful')
    end
  end
end
