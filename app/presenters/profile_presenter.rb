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
    aggregations[SolrDocument::FIELD_APO_TITLE.to_s].items
  end

  def collection_titles
    aggregations[SolrDocument::FIELD_COLLECTION_TITLE.to_s].items
  end

  def rights_descriptions
    aggregations['rights_descriptions_ssim'].items
  end

  def content_type
    aggregations['content_type_ssim'].items
  end
end
