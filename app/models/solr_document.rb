# frozen_string_literal: true

class SolrDocument
  include Blacklight::Solr::Document
  include ApoConcern
  include CollectionConcern

  FIELD_OBJECT_TYPE = :objectType_ssim
  FIELD_CONTENT_TYPE = :content_type_ssim
  FIELD_EMBARGO_STATUS = :embargo_status_ssim
  FIELD_EMBARGO_RELEASE_DATE = :embargo_release_dtsim
  FIELD_CATKEY_ID = :catkey_id_ssim
  FIELD_FOLIO_ID = :folio_instance_hrid_ssim
  FIELD_CREATED_DATE = :created_at_dttsi
  FIELD_REGISTERED_DATE = :registered_dttsim
  FIELD_LAST_ACCESSIONED_DATE = :accessioned_latest_dttsi
  FIELD_EARLIEST_ACCESSIONED_DATE = :accessioned_earliest_dttsi
  FIELD_LAST_PUBLISHED_DATE = :published_latest_dttsi
  FIELD_LAST_SUBMITTED_DATE = :submitted_latest_dttsi
  FIELD_LAST_DEPOSITED_DATE = :deposited_latest_dttsi
  FIELD_LAST_MODIFIED_DATE = :modified_latest_dttsi
  FIELD_LAST_OPENED_DATE = :opened_latest_dttsi
  FIELD_PRESERVATION_SIZE = :preserved_size_dbtsi
  FIELD_RELEASED_TO_EARTHWORKS = :released_to_earthworks_dttsi
  FIELD_RELEASED_TO_SEARCHWORKS = :released_to_searchworks_dttsi
  FIELD_RELEASED_TO = :released_to_ssim

  FIELD_TITLE = "sw_display_title_tesim"
  FIELD_AUTHOR = "sw_author_tesim"
  FIELD_LABEL = "obj_label_tesim"
  FIELD_PLACE = "originInfo_place_placeTerm_tesim"
  FIELD_PUBLISHER = "originInfo_publisher_tesim"
  FIELD_MODS_CREATED_DATE = "originInfo_date_created_tesim"
  FIELD_CURRENT_VERSION = "current_version_isi"
  FIELD_STATUS = "status_ssi"
  FIELD_ACCESS_RIGHTS = "rights_descriptions_ssim"
  FIELD_DEFAULT_ACCESS_RIGHTS = "default_rights_descriptions_ssim"
  FIELD_COPYRIGHT = "copyright_ssim"
  FIELD_USE_STATEMENT = "use_statement_ssim"
  FIELD_LICENSE = "use_license_machine_ssi"
  FIELD_PROJECT_TAG = "project_tag_ssim"
  FIELD_TAGS = "tag_ssim"
  FIELD_SOURCE_ID = "source_id_ssim"
  FIELD_BARCODE_ID = "barcode_id_ssim"
  FIELD_WORKFLOW_ERRORS = "wf_error_ssim"
  FIELD_CONSTITUENTS = "has_constituents_ssim"

  attribute :object_type, Blacklight::Types::String, FIELD_OBJECT_TYPE
  attribute :content_type, Blacklight::Types::String, FIELD_CONTENT_TYPE
  attribute :catkey, Blacklight::Types::String, FIELD_CATKEY_ID
  attribute :catkey, Blacklight::Types::String, FIELD_FOLIO_ID
  attribute :current_version, Blacklight::Types::String, FIELD_CURRENT_VERSION
  attribute :embargo_status, Blacklight::Types::String, FIELD_EMBARGO_STATUS
  attribute :embargo_release_date, Blacklight::Types::Date, FIELD_EMBARGO_RELEASE_DATE
  attribute :first_shelved_image, Blacklight::Types::String, :first_shelved_image_ss

  attribute :registered_date, Blacklight::Types::Date, FIELD_REGISTERED_DATE
  attribute :accessioned_date, Blacklight::Types::Array, FIELD_LAST_ACCESSIONED_DATE
  attribute :published_date, Blacklight::Types::Array, FIELD_LAST_PUBLISHED_DATE
  attribute :submitted_date, Blacklight::Types::Array, FIELD_LAST_SUBMITTED_DATE
  attribute :deposited_date, Blacklight::Types::Array, FIELD_LAST_DEPOSITED_DATE
  attribute :modified_date, Blacklight::Types::Array, FIELD_LAST_MODIFIED_DATE
  attribute :created_date, Blacklight::Types::Date, FIELD_CREATED_DATE
  attribute :opened_date, Blacklight::Types::Array, FIELD_LAST_OPENED_DATE
  attribute :preservation_size, Blacklight::Types::String, FIELD_PRESERVATION_SIZE
  attribute :released_to, Blacklight::Types::Array, FIELD_RELEASED_TO

  attribute :label, Blacklight::Types::String, FIELD_LABEL
  attribute :sw_title, Blacklight::Types::Array, FIELD_TITLE
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
    author: "dc_creator_ssi",
    language: "sw_language_ssim",
    format: "sw_format_ssim"
  )

  def embargoed?
    embargo_status == "embargoed"
  end

  # @return [boolean] true if NOT an adminPolicy or an agreement
  def publishable?
    item? || collection?
  end

  def admin_policy?
    object_type == "adminPolicy"
  end

  def agreement?
    object_type == "agreement"
  end

  def item?
    object_type == "item"
  end

  def virtual_object?
    return false unless item?

    constituents&.any?
  end

  def collection?
    object_type == "collection"
  end

  def thumbnail_url
    return nil unless first_shelved_image

    @thumbnail_url ||= begin
      file_id = File.basename(first_shelved_image, ".*")
      druid = Druid.new(id).without_namespace
      "#{Settings.stacks_url}/iiif/#{druid}%2F#{ERB::Util.url_encode(file_id)}/full/!400,400/0/default.jpg"
    end
  end

  ##
  # Access a SolrDocument's catkey identifier
  # @return [String, nil]
  def catkey_id
    catkey&.delete_prefix("catkey:")
  end

  ##
  # Access a SolrDocument's druid parsed from the id format of 'druid:abc123'
  # @return [String]
  def druid
    Druid.new(id).without_namespace
  end

  def title
    (sw_title.presence || [label]).join(" -- ")
  end

  def inspect
    "#<#{self.class.name}:#{object_id} @id=#{id}>"
  end
end
