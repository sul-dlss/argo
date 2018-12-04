# frozen_string_literal: true

##
# this job will reindex a list of DOR objects, locally performing the computation to
# generate the solr document (talking directly to Fedora to retrieve the object, and
# directly to Solr to update the index).
class LocalIndexingJob < ActiveJob::Base
  queue_as :indexing_local

  ##
  # Perform indexing job on a list of pids
  # @param [Array] pid_list
  def perform(pid_list)
    if Settings.INDEXING_JOB.SHOULD_PROFILE
      Argo::Indexer.reindex_pid_list_with_profiling pid_list, Settings.INDEXING_JOB.SHOULD_COMMIT_BATCHES
    else
      Argo::Indexer.reindex_pid_list pid_list, Settings.INDEXING_JOB.SHOULD_COMMIT_BATCHES
    end
  end
end
