# frozen_string_literal: true

module CollectionConcern
  extend Blacklight::Solr::Document

  FIELD_BARE_COLLECTION_ID = 'bare_member_of_collection_ssm'
  FIELD_COLLECTION_ID = 'member_of_collection_ssim'
  FIELD_COLLECTION_TITLE = 'collection_title_ssimdv'

  ##
  # Access a SolrDocument's *first* Collection druid
  # @return [String, nil]
  def collection_id
    collection_ids&.first
  end

  ##
  # Access a SolrDocument's Collection(s) druid
  # @return [Array<String>, nil]
  def collection_ids
    fetch(FIELD_COLLECTION_ID, nil)
  end

  ##
  # Access a SolrDocument's *first* Collection title
  # @return [String, nil]
  def collection_title
    collection_titles.first
  end

  ##
  # Access a SolrDocument's Collection(s) title
  # @return [Array<String>, nil]
  def collection_titles
    fetch(FIELD_COLLECTION_TITLE, [])
  end
end
