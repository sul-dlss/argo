# frozen_string_literal: true

##
# Used in the Profile view to provide convenience to the
# Blacklight::Solr::Response for easy view magic
class ProfilePresenter
  delegate :aggregations, to: :response

  attr_reader :response

  ##
  # @param [Blacklight::Solr::Response] response
  def initialize(response)
    @response = response
  end

  def apo_titles
    aggregations[SolrDocument::FIELD_APO_TITLE].items
  end

  def collection_titles
    aggregations[SolrDocument::FIELD_COLLECTION_TITLE].items
  end

  def rights_descriptions
    aggregations[SolrDocument::FIELD_ACCESS_RIGHTS].items
  end

  def content_type
    aggregations[SolrDocument::FIELD_CONTENT_TYPE].items
  end

  def use_statement
    aggregations['use_statement_ssim'].items
  end

  def copyright
    aggregations['copyright_ssim'].items
  end

  def use_license_machine
    aggregations[SolrDocument::FIELD_LICENSE].items
  end

  def sw_resource_type
    aggregations[SolrDocument::FIELD_SW_FORMAT].items
  end

  def date
    stats_field[SolrDocument::FIELD_PUBLICATION_DATE]
  end

  def sw_language
    aggregations[SolrDocument::FIELD_SW_LANGUAGE].items
  end

  def topic
    aggregations[SolrDocument::FIELD_TOPIC].items
  end

  def region
    aggregations[SolrDocument::FIELD_SUBJECT_GEOGRAPHIC].items
  end

  def genre
    aggregations[SolrDocument::FIELD_GENRE].items
  end

  def type_status_pivot
    pivots_field["#{SolrDocument::FIELD_OBJECT_TYPE},#{SolrDocument::FIELD_PROCESSING_STATUS}"]
  end

  def content_file_count
    stats_field['content_file_count_itsi']
  end

  def shelved_content_file_count
    stats_field['shelved_content_file_count_itsi']
  end

  def preserved_file_size
    stats_field[SolrDocument::FIELD_PRESERVATION_SIZE]
  end

  def published_to_purl
    facet_query_field['-rights_primary_ssi:"dark" AND published_dttsim:*']
  end

  private

  def stats_field
    response['stats']['stats_fields']
  end

  def pivots_field
    response['facet_counts']['facet_pivot']
  end

  def facet_query_field
    response['facet_counts']['facet_queries']
  end
end
