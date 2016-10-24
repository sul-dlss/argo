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

  def use_statement
    aggregations['use_statement_ssim'].items
  end

  def copyright
    aggregations['copyright_ssim'].items
  end

  def use_license_machine
    aggregations['use_license_machine_ssi'].items
  end

  def sw_resource_type
    aggregations['sw_format_ssim'].items
  end

  def sw_date
    [stats_field['sw_pub_date_facet_ssi']]
  end

  def sw_language
    aggregations['sw_language_ssim'].items
  end

  def sw_topic
    aggregations['topic_ssim'].items
  end

  def sw_region
    aggregations['sw_subject_geographic_ssim'].items
  end

  def sw_era
    aggregations['sw_subject_temporal_ssim'].items
  end

  def sw_genre
    aggregations['sw_genre_ssim'].items
  end

  def mods_title
    [stats_field['title_ssi']]
  end

  def mods_creator
    [stats_field['creator_ssi']]
  end

  private

  def stats_field
    response['stats']['stats_fields']
  end
end
