# frozen_string_literal: true

class ApoForm < ApplicationChangeSet
  include HasViewAccessWithCdl
  property :title, virtual: true
  property :agreement_object_id, virtual: true

  property :use_statement, virtual: true
  property :copyright_statement, virtual: true
  property :use_license, virtual: true
  property :default_workflows, virtual: true

  property :collection_radio, virtual: true
  property :collections_for_registration, virtual: true
  property :collection, virtual: true # These attributes get passed to the CollectionForm
  property :registered_by, virtual: true
  property :permissions, virtual: true

  validates :title, presence: true
  validates :agreement_object_id, presence: true

  DEFAULT_MANAGER_WORKGROUPS = %w[developer service-manager metadata-staff].freeze

  def self.model_name
    ::ActiveModel::Name.new(nil, nil, "Apo")
  end

  # needed for generating the update route
  def to_key
    Array(model&.externalIdentifier)
  end

  # @param [Cocina::Models::AdminPolicy,NilClass] model the object to update or nil for a new item
  # @param [Blacklight::SearchService] search_service a way to search solr
  def initialize(model, search_service:)
    super(model)
    @search_service = search_service
  end

  def setup_properties!(_options)
    if model
      self.title = model.description.title.first.value
      self.agreement_object_id = model.administrative.hasAgreement
      self.use_statement = model.administrative.accessTemplate&.useAndReproductionStatement
      self.copyright_statement = model.administrative.accessTemplate&.copyright
      self.use_license = model.administrative.accessTemplate&.license
      self.default_workflows = model.administrative.registrationWorkflow
      self.permissions = manage_permissions + view_permissions
      setup_view_access_with_cdl_properties(model.administrative.accessTemplate)
    else
      self.collection_radio = "none"
      self.default_workflows = ["registrationWF"]
      self.permissions = default_permissions
    end
  end

  def save_model
    @model = if persisted?
      AdminPolicyPersister.update(model, self)
    else
      AdminPolicyPersister.create(self)
    end
  end

  def id
    model.externalIdentifier
  end

  # @return [Array<SolrDocument>]
  def default_collection_objects
    @default_collection_objects ||=
      @search_service
        .fetch(default_collections, rows: default_collections.size)
        .last
        .sort_by do |solr_doc|
        solr_doc.label.downcase
      end
  end

  def to_param
    model.externalIdentifier
  end

  def license_options
    [["-- none --", ""]] + options_for_use_license_type(use_license)
  end

  private

  def default_collections
    return [] unless model

    Array(model.administrative.collectionsForRegistration)
  end

  # return a list of lists, where the sublists are pairs, with the first element being the text to display
  # in the selectbox, and the second being the value to submit for the entry.  include only non-deprecated
  # entries, unless the current value is a deprecated entry, in which case, include that entry with the
  # deprecation warning in a parenthetical.
  def options_for_use_license_type(current_value)
    # We use `#filter_map` here to remove nils from the options block (for unused deprecated licenses)
    Constants::LICENSE_OPTIONS.filter_map do |attributes|
      if attributes.fetch(:uri) == current_value && attributes.key?(:deprecation_warning)
        ["#{attributes.fetch(:label)} (#{attributes.fetch(:deprecation_warning)})", attributes.fetch(:uri)]
      elsif !attributes.key?(:deprecation_warning)
        [attributes.fetch(:label), attributes.fetch(:uri)]
      end
    end
  end

  def manage_permissions
    manage_role = model.administrative.roles&.find { |role| role.name == "dor-apo-manager" }
    managers = manage_role ? manage_role.members.map { |member| "#{member.type}:#{member.identifier}" } : []
    build_permissions(managers, "manage")
  end

  def view_permissions
    view_role = model.administrative.roles&.find { |role| role.name == "dor-apo-viewer" }
    viewers = view_role ? view_role.members.map { |member| "#{member.type}:#{member.identifier}" } : []
    build_permissions(viewers, "view")
  end

  def build_permissions(role_list, access)
    role_list.map do |name|
      if name.starts_with? "workgroup:"
        {name: name.sub(/^workgroup:[^:]*:/, ""), type: "group", access:}
      else
        {name: name.sub(/^sunetid:/, ""), type: "person", access:}
      end
    end
  end

  def default_permissions
    DEFAULT_MANAGER_WORKGROUPS.map do |name|
      {name:, type: "group", access: "manage"}
    end
  end
end
