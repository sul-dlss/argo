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
  FIELD_FOLIO_INSTANCE_HRID = :folio_instance_hrid_ssim
  FIELD_DOI = :doi_ssim
  FIELD_ORCIDS = :contributor_orcids_ssim
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

  FIELD_TITLE = :sw_display_title_tesim
  FIELD_AUTHOR = :sw_author_tesim
  FIELD_LABEL = :obj_label_tesim
  FIELD_PLACE = :originInfo_place_placeTerm_tesim
  FIELD_PUBLISHER = :originInfo_publisher_tesim
  FIELD_MODS_CREATED_DATE = :originInfo_date_created_tesim
  FIELD_CURRENT_VERSION = :current_version_isi
  FIELD_STATUS = :status_ssi
  FIELD_ACCESS_RIGHTS = :rights_descriptions_ssim
  FIELD_DEFAULT_ACCESS_RIGHTS = :default_rights_descriptions_ssim
  FIELD_COPYRIGHT = :copyright_ssim
  FIELD_USE_STATEMENT = :use_statement_ssim
  FIELD_LICENSE = :use_license_machine_ssi
  FIELD_PROJECT_TAG = :project_tag_ssim
  FIELD_TAGS = :tag_ssim
  FIELD_SOURCE_ID = :source_id_ssim
  FIELD_BARCODE_ID = :barcode_id_ssim
  FIELD_WORKFLOW_ERRORS = :wf_error_ssim
  FIELD_CONSTITUENTS = :has_constituents_ssim

  attribute :object_type, :string, field: FIELD_OBJECT_TYPE
  attribute :content_type, :string, field: FIELD_CONTENT_TYPE
  attribute :catkey, :string, field: FIELD_CATKEY_ID
  attribute :folio_instance_hrid, :string, field: FIELD_FOLIO_INSTANCE_HRID
  attribute :doi, :string, field: FIELD_DOI
  attribute :orcids, :array, field: FIELD_ORCIDS
  attribute :current_version, :string, field: FIELD_CURRENT_VERSION
  attribute :embargo_status, :string, field: FIELD_EMBARGO_STATUS
  attribute :embargo_release_date, :date, field: FIELD_EMBARGO_RELEASE_DATE
  attribute :first_shelved_image, :string, field: :first_shelved_image_ss

  attribute :registered_date, :date, field: FIELD_REGISTERED_DATE
  attribute :accessioned_date, :array, field: FIELD_LAST_ACCESSIONED_DATE
  attribute :published_date, :array, field: FIELD_LAST_PUBLISHED_DATE
  attribute :submitted_date, :array, field: FIELD_LAST_SUBMITTED_DATE
  attribute :deposited_date, :array, field: FIELD_LAST_DEPOSITED_DATE
  attribute :modified_date, :array, field: FIELD_LAST_MODIFIED_DATE
  attribute :created_date, :date, field: FIELD_CREATED_DATE
  attribute :opened_date, :array, field: FIELD_LAST_OPENED_DATE
  attribute :preservation_size, :value, field: FIELD_PRESERVATION_SIZE
  attribute :released_to, :array, field: FIELD_RELEASED_TO

  attribute :label, :string, field: FIELD_LABEL
  attribute :sw_title, :array, field: FIELD_TITLE
  attribute :author, :string, field: FIELD_AUTHOR
  attribute :place, :string, field: FIELD_PLACE
  attribute :publisher, :string, field: FIELD_PUBLISHER
  attribute :mods_created_date, :string, field: FIELD_MODS_CREATED_DATE
  attribute :status, :string, field: FIELD_STATUS
  attribute :access_rights, :array, field: FIELD_ACCESS_RIGHTS
  attribute :default_access_rights, :string, field: FIELD_DEFAULT_ACCESS_RIGHTS
  attribute :copyright, :string, field: FIELD_COPYRIGHT
  attribute :use_statement, :string, field: FIELD_USE_STATEMENT
  attribute :license, :string, field: FIELD_LICENSE
  attribute :project_tag, :string, field: FIELD_PROJECT_TAG
  attribute :source_id, :string, field: FIELD_SOURCE_ID
  attribute :barcode, :string, field: FIELD_BARCODE_ID
  attribute :tags, :array, field: FIELD_TAGS
  attribute :constituents, :array, field: FIELD_CONSTITUENTS

  # self.unique_key = 'id'

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

  def catalog_record_id
    return folio_instance_hrid if Settings.enabled_features.folio

    catkey
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
