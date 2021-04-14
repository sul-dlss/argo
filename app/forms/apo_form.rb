# frozen_string_literal: true

# Inspired by Reform, but not exactly reform, because of existing deficiencies
# in dor-services:
#  https://github.com/sul-dlss/dor-services/pull/360
class ApoForm
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  DEFAULT_MANAGER_WORKGROUPS = %w[developer service-manager metadata-staff].freeze

  attr_reader :model, :params, :default_collection_pid, :search_service

  # needed so that the form routes to `/apo` rather than '/apo_form'
  def self.model_name
    Struct.new(:param_key, :route_key, :i18n_key, :name).new('apo_form', 'apo', 'apo', 'Apo')
  end

  # needed for generating the update route
  def to_key
    Array(@model&.externalIdentifier)
  end

  # @param [Cocina::Models::AdminPolicy,NilClass] model the object to update or nil for a new item
  # @param [Blacklight::SearchService] search_service a way to search solr
  def initialize(model, search_service:)
    @model = model
    @search_service = search_service
    self.default_rights = 'world'
    self.default_workflows = ['registrationWF']
    populate_from_model if model
    @errors = []
  end

  def populate_from_model
    self.title = model.description.title.first.value
    self.agreement_object_id = model.administrative.referencesAgreement
    self.default_rights = model.administrative.defaultAccess&.access
    self.use_statement = model.administrative.defaultAccess&.useAndReproductionStatement
    self.copyright_statement = model.administrative.defaultAccess&.copyright
    self.use_license = model.administrative.defaultAccess&.license
    self.default_workflows = model.administrative.registrationWorkflow
  end

  attr_accessor :use_license, :agreement_object_id, :use_statement, :copyright_statement,
                :default_rights, :title, :default_workflows

  def persisted?
    !model.nil?
  end

  # @return [Array<Hash>] the list of permissions (grants for users/groups) on this object
  def permissions
    return default_permissions unless persisted?

    manage_permissions + view_permissions
  end

  # @return [Array<SolrDocument>]
  def default_collection_objects
    @default_collection_objects ||=
      search_service
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
    [['-- none --', '']] + options_for_use_license_type(use_license)
  end

  def collection_radio
    'none'
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def default_object_rights
    return default_rights if model.nil?
    return "loc:#{model.administrative.defaultAccess.readLocation}" if default_rights == 'location-based'
    return 'cdl-stanford-nd' if model.administrative&.defaultAccess&.controlledDigitalLending
    return "#{default_rights}-nd" if model.administrative&.defaultAccess&.download == 'none' && default_rights.in?(%w[stanford world])

    default_rights
  end
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

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
    Constants::LICENSE_OPTIONS.map do |key, attributes|
      if key == current_value && attributes.key?(:deprecation_warning)
        ["#{attributes.fetch(:label)} (#{attributes.fetch(:deprecation_warning)})", attributes.fetch(:uri)]
      elsif !attributes.key?(:deprecation_warning)
        [attributes.fetch(:label), attributes.fetch(:uri)]
      end
    end.compact # the options block will produce nils for unused deprecated entries, compact will get rid of them
  end

  def manage_permissions
    manage_role = model.administrative.roles&.find { |role| role.name == 'dor-apo-manager' }
    managers = manage_role ? manage_role.members.map { |member| "#{member.type}:#{member.identifier}" } : []
    build_permissions(managers, 'manage')
  end

  def view_permissions
    view_role = model.administrative.roles&.find { |role| role.name == 'dor-apo-viewer' }
    viewers = view_role ? view_role.members.map { |member| "#{member.type}:#{member.identifier}" } : []
    build_permissions(viewers, 'view')
  end

  def build_permissions(role_list, access)
    role_list.map do |name|
      if name.starts_with? 'workgroup:'
        { name: name.sub(/^workgroup:[^:]*:/, ''), type: 'group', access: access }
      else
        { name: name.sub(/^sunetid:/, ''), type: 'person', access: access }
      end
    end
  end

  def default_permissions
    DEFAULT_MANAGER_WORKGROUPS.map do |name|
      { name: name, type: 'group', access: 'manage' }
    end
  end
end
