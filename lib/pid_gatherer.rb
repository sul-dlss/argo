module Argo
  ##
  # Gatherer of the PIDS, used for Argo indexing
  class PidGatherer
    attr_writer :all_pids, :solr_pids, :workflow_pids, :agreement_pids, :apo_pids, :hydrus_apo_pids, :collection_pids, :hydrus_collection_pids, :set_pids, :item_pids

    def initialize(should_log_to_stdout = true, should_exclude_invalid_druids = true)
      if should_log_to_stdout
        @logger = Logger.new(STDOUT)
      else
        @logger = Argo::Indexer.index_logger
      end
      @should_exclude_invalid_druids = should_exclude_invalid_druids
    end

    def filter_invalid_druids_if_needed(pid_list)
      if @should_exclude_invalid_druids
        pid_list.select { |pid| DruidTools::Druid.valid? pid }
      else
        pid_list
      end
    end

    ##
    # @return [Array<String>]
    def all_pids
      @all_pids ||= begin
        @logger.info 'querying fedora for all pids...'

        dor_pids = []
        Dor::SearchService.iterate_over_pids(in_groups_of: 1000, mode: :group) do |chunk|
          dor_pids += chunk
        end
        dor_pids
      end
      @logger.info "found #{@all_pids.length} pids in fedora (all pids, unfiltered)"

      filter_invalid_druids_if_needed @all_pids
    end

    ##
    # defaults to returning them all
    def solr_pids(q = '*:*')
      @solr_pids ||= begin
        @logger.info "querying solr for indexed pids, (q=#{q})..."

        start = 0
        solr_pids = []
        resp = Dor::SearchService.query(q, :sort => 'id asc', :rows => 1000, :start => start, :fl => ['id'])
        while resp.docs.length > 0
          solr_pids += resp.docs.map { |doc| doc['id'] }
          start += 1000
          resp = Dor::SearchService.query(q, :sort => 'id asc', :rows => 1000, :start => start, :fl => ['id'])
        end
        solr_pids
      end
      @logger.info "found #{@solr_pids.length} pids in solr (unfiltered)"

      filter_invalid_druids_if_needed @solr_pids
    end

    ##
    # @return [Array<String>]
    def uber_apo_pids
      @uber_apo_pids ||= [SolrDocument::UBER_APO_ID]
    end

    ##
    # @return [Array<String>]
    def workflow_pids
      @workflow_pids ||= pids_for_model_type '<info:fedora/afmodel:Dor_WorkflowObject>'
    end

    ##
    # @return [Array<String>]
    def agreement_pids
      @agreement_pids ||= pids_for_model_type '<info:fedora/afmodel:agreement>'
    end

    ##
    # @return [Array<String>]
    def hydrus_uber_apo_pids
      @hydrus_uber_apo_pids || [SolrDocument::HYDRUS_UBER_APO_ID]
    end

    ##
    # @return [Array<String>]
    def apo_pids
      @apo_pids ||= pids_for_model_type '<info:fedora/afmodel:Dor_AdminPolicyObject>'
    end

    ##
    # @return [Array<String>]
    def hydrus_apo_pids
      @hydrus_apo_pids ||= pids_for_model_type '<info:fedora/afmodel:Hydrus_AdminPolicyObject>'
    end

    ##
    # @return [Array<String>]
    def collection_pids
      @collection_pids ||= pids_for_model_type '<info:fedora/afmodel:Dor_Collection>'
    end

    ##
    # @return [Array<String>]
    def hydrus_collection_pids
      @hydrus_collection_pids ||= pids_for_model_type '<info:fedora/afmodel:Hydrus_Collection>'
    end

    ##
    # @return [Array<String>]
    def set_pids
      @set_pids ||= pids_for_model_type '<info:fedora/afmodel:Dor_Set>'
    end

    def item_pids
      @item_pids ||= pids_for_model_type '<info:fedora/afmodel:Dor_Item>'
    end

    ##
    # A list of lists for reindexing all of the objects in Fedora.  Each list represents a group of objects for a given object type, and lists are returned
    # in the order that the groups should be indexed (e.g. uber_apo_pids are the 0th group, and should be indexed before all other lists, and so on).
    # @return [Array<Array<String>>]
    def pid_lists_for_full_reindex
      [uber_apo_pids, workflow_pids, agreement_pids, hydrus_uber_apo_pids, apo_pids, hydrus_apo_pids, collection_pids, hydrus_collection_pids, set_pids, remaining_pids]
    end

    ##
    # Same structure as pid_lists_for_full_reindex, but only returns pids that aren't yet in solr.
    # @return [Array<Array<String>>]
    def pid_lists_for_unindexed
      pid_lists_for_full_reindex.map do |pid_list|
        pid_list - solr_pids
      end
    end

    ##
    # all the pids that aren't yet in solr
    # @return [Array<String>]
    def unindexed_pids
      all_pids - solr_pids
    end

    ##
    # all_pids with other pid groups removed
    # @return [Array<String>]
    def remaining_pids
      @remaining_pids ||= all_pids -
        (uber_apo_pids + workflow_pids + agreement_pids + hydrus_uber_apo_pids +
        apo_pids + hydrus_apo_pids + collection_pids + hydrus_collection_pids +
        set_pids)
    end

    private

    ##
    # Query the Dor SearchService for a specific model
    def pids_for_model_type(model_type)
      @logger.info "querying fedora for pids for model_type=#{model_type}..."

      pid_list = Dor::SearchService.risearch 'select $object from <#ri> where $object ' \
        "<fedora-model:hasModel> #{model_type}", { :limit => nil }
      @logger.info "found #{pid_list.length} pids for #{model_type} (unfiltered)"

      filter_invalid_druids_if_needed pid_list
    end
  end
end
