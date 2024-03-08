# frozen_string_literal: true

# Looks up collection name (title) from Solr
class CollectionNameService
  # @return [NilClass,String] the name (title) of the collection if found in solr
  def self.find(collection_id)
    solr_doc = SearchService.query("id:\"#{collection_id}\"",
                                   rows: 1,
                                   fl: SolrDocument::FIELD_TITLE)['response']['docs'].first
    return unless solr_doc

    coll_title = solr_doc[SolrDocument::FIELD_TITLE]
    coll_title.is_a?(Array) ? coll_title.first : coll_title
  end
end
