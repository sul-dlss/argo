# frozen_string_literal: true

class SolrDocument
  include Blacklight::Solr::Document
  include ApoConcern
  include CollectionConcern

  FIELD_ACCESS_RIGHTS = 'rights_descriptions_ssimdv'
  FIELD_AUTHOR = 'author_display_ss'
  FIELD_BARCODE_ID = 'barcode_id_ssimdv'
  FIELD_BARE_DRUID = 'druid_bare_ssi'
  FIELD_CONSTITUENTS = 'has_constituents_ssimdv'
  FIELD_CONSTITUENTS_COUNT = 'constituents_count_ips'
  FIELD_CONTENT_FILE_MIMETYPES = 'content_file_mimetypes_ssimdv'
  FIELD_CONTENT_FILE_ROLES = 'content_file_roles_ssimdv'
  FIELD_CONTENT_TYPE = 'content_type_ssimdv'
  FIELD_COPYRIGHT = 'copyright_ssim'
  FIELD_CREATED_DATE = 'created_at_dttsi'
  FIELD_CURRENT_VERSION = 'current_version_ipsidv'
  FIELD_DEFAULT_ACCESS_RIGHTS = 'default_rights_descriptions_ssim'
  FIELD_DISSERTATION_ID = 'dissertation_id_ss'
  FIELD_DOI = 'doi_ssimdv'
  FIELD_EARLIEST_ACCESSIONED_DATE = 'accessioned_earliest_dtpsidv'
  FIELD_EMBARGO_RELEASE_DATE = 'embargo_release_dtpsimdv'
  FIELD_EMBARGO_STATUS = 'embargo_status_ssim'
  FIELD_EXPLODED_NONPROJECT_TAG = 'exploded_nonproject_tag_ssimdv'
  FIELD_EXPLODED_PROJECT_TAG = 'exploded_project_tag_ssimdv'
  FIELD_FOLIO_INSTANCE_HRID = 'folio_instance_hrid_ssim'
  FIELD_FORMATTED_EARLIEST_ACCESSIONED_DATE = 'formatted_accessioned_earliest_ss'
  FIELD_FORMATTED_EMBARGO_RELEASE_DATE = 'formatted_embargo_release_ss'
  FIELD_FORMATTED_PUBLISHED_EARLIEST_DATE = 'formatted_published_earliest_ss'
  FIELD_FORMATTED_REGISTERED_EARLIEST = 'formatted_registered_earliest_ss'
  FIELD_HUMAN_PRESERVED_SIZE = 'human_preserved_size_ss'
  FIELD_GENRE = 'genre_ssimdv'
  FIELD_LABEL = 'obj_label_tesim'
  FIELD_LAST_ACCESSIONED_DATE = 'accessioned_latest_dtpsidv'
  FIELD_LAST_OPENED_DATE = 'opened_latest_dtpsidv'
  FIELD_LAST_PUBLISHED_DATE = 'published_latest_dtpsidv'
  FIELD_LICENSE = 'use_license_machine_ssidv'
  FIELD_METADATA_SOURCE = 'metadata_source_ssimdv'
  FIELD_MODS_TYPE_OF_RESOURCE = 'mods_typeOfResource_ssimdv'
  FIELD_OBJECT_TYPE = 'objectType_ssimdv'
  FIELD_ORCIDS = 'contributor_orcids_ssimdv'
  FIELD_PROCESSING_STATUS = 'processing_status_text_ssidv'
  FIELD_MODS_CREATED_DATE = 'originInfo_date_created_tesim'
  FIELD_PLACE = 'originInfo_place_placeTerm_tesim'
  FIELD_PRESERVATION_SIZE = 'preserved_size_lpsidv'
  FIELD_PROJECT_TAG = 'project_tag_ssim'
  FIELD_PUBLICATION_DATE = 'publication_year_ssidv'
  FIELD_PUBLISHER = 'originInfo_publisher_tesim'
  FIELD_PURL = 'purl_ss'
  FIELD_REGISTERED_DATE = 'registered_dtpsimdv'
  FIELD_RELEASED_TO = 'released_to_ssim'
  FIELD_RELEASED_TO_EARTHWORKS = 'released_to_earthworks_dtpsidv'
  FIELD_RELEASED_TO_PURL_SITEMAP = 'released_to_purl_sitemap_dtpsidv'
  FIELD_RELEASED_TO_SEARCHWORKS = 'released_to_searchworks_dtpsidv'
  FIELD_SOURCE_ID = 'source_id_ssi'
  FIELD_STATUS = 'status_ssi'
  FIELD_SUBJECT_GEOGRAPHIC = 'subject_place_ssimdv'
  FIELD_SW_FORMAT = 'sw_format_ssimdv'
  FIELD_SW_RESOURCE_TYPE = 'sw_resource_type_ssimdv'
  FIELD_SW_LANGUAGE = 'sw_language_names_ssimdv'
  FIELD_TAGS = 'tag_ssim'
  FIELD_TICKET_TAG = 'ticket_tag_ssim'
  FIELD_TITLE = 'display_title_ss'
  FIELD_TOPIC = 'subject_topic_other_ssimdv'
  FIELD_USE_STATEMENT = 'use_statement_ssim'
  FIELD_WORKFLOW_ERRORS = 'wf_error_ssim'
  FIELD_WORKFLOW_WPS = 'wf_wps_ssimdv'

  attribute :object_type, Blacklight::Types::String, FIELD_OBJECT_TYPE
  attribute :content_type, Blacklight::Types::String, FIELD_CONTENT_TYPE
  attribute :folio_instance_hrid, Blacklight::Types::String, FIELD_FOLIO_INSTANCE_HRID
  attribute :doi, Blacklight::Types::String, FIELD_DOI
  attribute :orcids, Blacklight::Types::Array, FIELD_ORCIDS
  attribute :current_version, Blacklight::Types::String, FIELD_CURRENT_VERSION
  attribute :embargo_status, Blacklight::Types::String, FIELD_EMBARGO_STATUS
  attribute :embargo_release_date, Blacklight::Types::Date, FIELD_EMBARGO_RELEASE_DATE
  attribute :first_shelved_image, Blacklight::Types::String, :first_shelved_image_ss

  attribute :registered_date, Blacklight::Types::Date, FIELD_REGISTERED_DATE
  attribute :accessioned_date, Blacklight::Types::Array, FIELD_LAST_ACCESSIONED_DATE
  attribute :published_date, Blacklight::Types::Array, FIELD_LAST_PUBLISHED_DATE
  attribute :created_date, Blacklight::Types::Date, FIELD_CREATED_DATE
  attribute :opened_date, Blacklight::Types::Array, FIELD_LAST_OPENED_DATE
  attribute :preservation_size, Blacklight::Types::Value, FIELD_PRESERVATION_SIZE
  attribute :released_to, Blacklight::Types::Array, FIELD_RELEASED_TO

  attribute :label, Blacklight::Types::String, FIELD_LABEL
  attribute :title_display, Blacklight::Types::String, FIELD_TITLE
  attribute :author, Blacklight::Types::String, FIELD_AUTHOR
  attribute :place, Blacklight::Types::String, FIELD_PLACE
  attribute :publisher, Blacklight::Types::String, FIELD_PUBLISHER
  attribute :mods_created_date, Blacklight::Types::String, FIELD_MODS_CREATED_DATE
  attribute :status, Blacklight::Types::String, FIELD_STATUS
  attribute :access_rights, Blacklight::Types::Array, FIELD_ACCESS_RIGHTS
  attribute :default_access_rights, Blacklight::Types::String, FIELD_DEFAULT_ACCESS_RIGHTS
  attribute :copyright, Blacklight::Types::String, FIELD_COPYRIGHT
  attribute :use_statement, Blacklight::Types::String, FIELD_USE_STATEMENT
  attribute :license, Blacklight::Types::String, FIELD_LICENSE
  attribute :project_tag, Blacklight::Types::String, FIELD_PROJECT_TAG
  attribute :source_id, Blacklight::Types::String, FIELD_SOURCE_ID
  attribute :barcode, Blacklight::Types::String, FIELD_BARCODE_ID
  attribute :tags, Blacklight::Types::Array, FIELD_TAGS
  attribute :constituents, Blacklight::Types::Array, FIELD_CONSTITUENTS

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
    language: SolrDocument::FIELD_SW_LANGUAGE,
    format: SolrDocument::FIELD_SW_RESOURCE_TYPE
  )

  def embargoed?
    embargo_status == 'embargoed'
  end

  # @return [boolean] true if NOT an adminPolicy or an agreement
  def publishable?
    item? || collection?
  end

  def admin_policy?
    object_type == 'adminPolicy'
  end

  def agreement?
    object_type == 'agreement'
  end

  def item?
    object_type == 'item'
  end

  def virtual_object?
    return false unless item?

    constituents&.any?
  end

  def collection?
    object_type == 'collection'
  end

  def thumbnail_url
    return nil unless first_shelved_image

    @thumbnail_url ||= begin
      file_id = File.basename(first_shelved_image, '.*')
      druid = Druid.new(id).without_namespace
      "#{Settings.stacks_url}/iiif/#{druid}%2F#{ERB::Util.url_encode(file_id)}/full/!400,400/0/default.jpg"
    end
  end

  def catalog_record_id
    folio_instance_hrid
  end

  ##
  # Access a SolrDocument's druid parsed from the id format of 'druid:abc123'
  # @return [String]
  def druid
    Druid.new(id).without_namespace
  end

  def inspect
    "#<#{self.class.name}:#{object_id} @id=#{id}>"
  end
end
