module Argo
  module CustomSearch
    extend ActiveSupport::Concern

    ##
    # Returns an unlimited (> 10,000,000) return of PIDs only from Solr if
    # `:pids_only` = true is provided in user_params
    def pids_only(solr_parameters, user_params)
      return unless user_params[:pids_only]
      solr_parameters[:fl] ||= []
      solr_parameters[:fl] << 'id'
      solr_parameters[:rows] = 99_999_999
      solr_parameters[:facet] = false
    end
  end
end
