module Argo
  ##
  # Gatherer of the PIDS, used for Argo indexing
  class PidGatherer
    def initialize(should_log_to_stdout = true)
      if should_log_to_stdout
        @logger = Logger.new(STDOUT)
      else
        @logger = Argo::Indexer.index_logger
      end
    end

    ##
    # @return [Array<Array<String>>]
    def pid_lists_for_full_reindex
      [uber_apo_pids, workflow_pids, agreement_pids, hydrus_uber_apo_pids, apo_pids, hydrus_apo_pids, collection_pids, hydrus_collection_pids, set_pids, remaining_pids]
    end

    ##
    # @return [Array<String>]
    def uber_apo_pids
      @uber_apo_pids ||= ['druid:hv992ry2431']
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
      @hydrus_uber_apo_pids || ['druid:zw306xn5593']
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

    ##
    # @return [Array<String>]
    def all_pids
      @logger.info 'querying fedora for all pids...'

      @all_pids ||= begin
        dor_pids = []
        Dor::SearchService.iterate_over_pids(in_groups_of: 1000, mode: :group) do |chunk|
          dor_pids += chunk
        end
        dor_pids
      end
      @logger.info "found #{@all_pids.length} pids in fedora (all pids)"

      @all_pids
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
        "<fedora-model:hasModel> #{model_type}"
      @logger.info "found #{pid_list.length} pids for #{model_type}"

      pid_list
    end
  end
end
