# frozen_string_literal: true

# dor-services-app writes Solr documents with `commitWithin: 5000` (see its Indexer), so an
#   object it has just registered or reindexed is not searchable for up to five seconds.
#   Capybara's retries do not help: `have_text` re-examines the already rendered results page
#   rather than re-running the search. Specs that register objects and then exercise search
#   therefore need to force the commit instead of waiting it out.
module SolrCommit
  def self.commit
    blacklight_config = CatalogController.blacklight_config
    blacklight_config.repository_class.new(blacklight_config).connection.soft_commit
  end
end
