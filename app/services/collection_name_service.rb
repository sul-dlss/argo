# frozen_string_literal: true

# Looks up collection names from solr
class CollectionNameService
  # @return [NilClass,String] the name of the collection if found in solr
  def self.find(collection_id)
    solr_doc = SearchService.query("id:\"#{collection_id}\"",
      rows: 1,
      fl: SolrDocument::FIELD_TITLE)["response"]["docs"].first
    return unless solr_doc

    solr_doc[SolrDocument::FIELD_TITLE].first
  end
end
