# frozen_string_literal: true

class SolrDocument
  include Blacklight::Solr::Document
  include ApoConcern
  include CollectionConcern

  FIELD_OBJECT_TYPE               = :objectType_ssim
  FIELD_EMBARGO_STATUS            = :embargo_status_ssim
  FIELD_EMBARGO_RELEASE_DATE      = :embargo_release_dtsim
  FIELD_CATKEY_ID                 = :catkey_id_ssim
  FIELD_REGISTERED_DATE           = :registered_dttsim
  FIELD_LAST_ACCESSIONED_DATE     = :accessioned_latest_dttsi
  FIELD_EARLIEST_ACCESSIONED_DATE = :accessioned_earliest_dttsi
  FIELD_LAST_PUBLISHED_DATE       = :published_latest_dttsi
  FIELD_LAST_SUBMITTED_DATE       = :submitted_latest_dttsi
  FIELD_LAST_DEPOSITED_DATE       = :deposited_latest_dttsi
  FIELD_LAST_MODIFIED_DATE        = :modified_latest_dttsi
  FIELD_LAST_OPENED_DATE          = :opened_latest_dttsi
  FIELD_PRESERVATION_SIZE         = :preserved_size_dbtsi
  FIELD_RELEASED_TO               = :released_to_ssim
  FIELD_TITLE                     = 'sw_display_title_tesim'
  FIELD_AUTHOR                    = 'sw_author_tesim'
  FIELD_LABEL                     = 'obj_label_tesim'
  FIELD_PLACE                     = 'originInfo_place_placeTerm_tesim'
  FIELD_PUBLISHER                 = 'originInfo_publisher_tesim'
  FIELD_CREATED_DATE              = 'originInfo_date_created_tesim'
  FIELD_CURRENT_VERSION           = 'current_version_isi'

  attribute :object_type, Blacklight::Types::String, FIELD_OBJECT_TYPE
  attribute :catkey, Blacklight::Types::String, FIELD_CATKEY_ID
  attribute :current_version, Blacklight::Types::String, FIELD_CURRENT_VERSION
  attribute :embargo_status, Blacklight::Types::String, FIELD_EMBARGO_STATUS
  attribute :embargo_release_date, Blacklight::Types::String, FIELD_EMBARGO_RELEASE_DATE
  attribute :dor_services_version, Blacklight::Types::String, :dor_services_version_ssi
  attribute :first_shelved_image, Blacklight::Types::String, :first_shelved_image_ss

  attribute :registered_date, Blacklight::Types::Array, FIELD_REGISTERED_DATE
  attribute :accessioned_date, Blacklight::Types::Array, FIELD_LAST_ACCESSIONED_DATE
  attribute :published_date, Blacklight::Types::Array, FIELD_LAST_PUBLISHED_DATE
  attribute :submitted_date, Blacklight::Types::Array, FIELD_LAST_SUBMITTED_DATE
  attribute :deposited_date, Blacklight::Types::Array, FIELD_LAST_DEPOSITED_DATE
  attribute :modified_date, Blacklight::Types::Array, FIELD_LAST_MODIFIED_DATE
  attribute :opened_date, Blacklight::Types::Array, FIELD_LAST_OPENED_DATE
  attribute :preservation_size, Blacklight::Types::String, FIELD_PRESERVATION_SIZE
  attribute :released_to, Blacklight::Types::Array, FIELD_RELEASED_TO

  attribute :label, Blacklight::Types::String, FIELD_LABEL
  attribute :sw_title, Blacklight::Types::Array, FIELD_TITLE
  attribute :author, Blacklight::Types::String, FIELD_AUTHOR
  attribute :place, Blacklight::Types::String, FIELD_PLACE
  attribute :publisher, Blacklight::Types::String, FIELD_PUBLISHER
  attribute :created_date, Blacklight::Types::String, FIELD_CREATED_DATE

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

  def embargoed?
    embargo_status == 'embargoed'
  end

  def admin_policy?
    object_type == 'adminPolicy'
  end

  def item?
    object_type == 'item'
  end

  def collection?
    object_type == 'collection'
  end

  def thumbnail_url
    return nil unless first_shelved_image

    @thumbnail_url ||= begin
      file_id = File.basename(first_shelved_image, '.*')
      druid = id.delete_prefix('druid:')
      "#{Settings.stacks_url}/iiif/#{druid}%2F#{ERB::Util.url_encode(file_id)}/full/!400,400/0/default.jpg"
    end
  end

  ##
  # Access a SolrDocument's catkey identifier
  # @return [String, nil]
  def catkey_id
    catkey&.delete_prefix('catkey:')
  end

  ##
  # Access a SolrDocument's druid parsed from the id format of 'druid:abc123'
  # @return [String]
  def druid
    id.delete_prefix('druid:')
  end

  def title
    (sw_title.presence || [label]).join(' -- ')
  end
end
