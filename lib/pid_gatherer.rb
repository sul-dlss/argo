module Argo
  ##
  # Gatherer of the PIDS, used for Argo indexing
  class PidGatherer
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
      @all_pids ||= begin
        dor_pids = []
        Dor::SearchService.iterate_over_pids(in_groups_of: 1000, mode: :group) do |chunk|
          dor_pids += chunk
        end
        dor_pids
      end
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
      Dor::SearchService.risearch 'select $object from <#ri> where $object ' \
        "<fedora-model:hasModel> #{model_type}"
    end
  end
end
