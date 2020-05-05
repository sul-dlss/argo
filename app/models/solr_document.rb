# frozen_string_literal: true

class SolrDocument
  include Blacklight::Solr::Document
  include ApoConcern
  include CatkeyConcern
  include CollectionConcern
  include DruidConcern
  include TitleConcern
  include DocumentDateConcern
  include PreservationSizeConcern
  include ObjectTypeConcern

  FIELD_EMBARGO_STATUS       = :embargo_status_ssim
  FIELD_EMBARGO_RELEASE_DATE = :embargo_release_dtsim

  attribute :embargo_status, Blacklight::Types::String, FIELD_EMBARGO_STATUS
  attribute :embargo_release_date, Blacklight::Types::String, FIELD_EMBARGO_RELEASE_DATE

  def embargoed?
    embargo_status == 'embargoed'
  end

  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)
  field_semantics.merge!(
    title: FIELD_TITLE,
    author: 'dc_creator_ssi',
    language: 'sw_language_ssim',
    format: 'sw_format_ssim'
  )

  attribute :versions, Blacklight::Types::Array, 'versions_ssm'

  # These values are used to drive the display for the datastream table on the item show page
  # This method is now excluding the workflows datastream because this datastream is deprecated.
  # @return[Array<Hash>] the deserialized datastream attributes
  def datastreams
    specs = fetch('ds_specs_ssim', []).map do |spec_string|
      Hash[[:dsid, :control_group, :mime_type, :version, :size, :label].zip(spec_string.split(/\|/))]
    end
    specs.filter { |spec| spec[:dsid] != 'workflows' }
  end
end
