# frozen_string_literal: true

# Searches against Solr
class SearchService
  class << self
    def query(query, args = {})
      params = args.merge(q: query)
      params[:start] ||= 0
      solr.get 'select', params: params
    end

    delegate :blacklight_config, to: CatalogController

    def solr
      blacklight_config.repository_class.new(blacklight_config).connection
    end
  end
end
