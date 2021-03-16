# frozen_string_literal: true

# Represents a set of changes to an admin policy.
class AdminPolicyChangeSet # rubocop:disable Metrics/ClassLength
  def initialize(model: nil)
    @model = model
    @changes = {}
    yield self if block_given?
  end

  attr_reader :model

  def save
    @model = AdminPolicyChangeSetPersister.update(model, self)
  end

  def new_record?
    model.nil?
  end

  def validate(params)
    params.each do |k, v|
      public_send("#{k}=", v.presence)
    end

    title.present? && agreement_object_id.present?
  end

  def use_license=(license)
    @changes[:use_license] = license
  end

  def use_license
    @changes[:use_license]
  end

  def use_license_changed?
    @changes.key?(:use_license)
  end

  def registered_by=(user)
    @changes[:registered_by] = user
  end

  def registered_by
    @changes[:registered_by]
  end

  def registered_by_changed?
    @changes.key?(:registered_by)
  end

  def agreement_object_id=(id)
    @changes[:agreement_object_id] = id
  end

  def agreement_object_id
    @changes[:agreement_object_id]
  end

  def agreement_object_id_changed?
    @changes.key?(:agreement_object_id)
  end

  def use_statement=(statement)
    @changes[:use_statement] = statement
  end

  def use_statement
    @changes[:use_statement]
  end

  def use_statement_changed?
    @changes.key?(:use_statement)
  end

  def copyright_statement=(statement)
    @changes[:copyright_statement] = statement
  end

  def copyright_statement
    @changes[:copyright_statement]
  end

  def copyright_statement_changed?
    @changes.key?(:copyright_statement)
  end

  def default_rights=(rights)
    @changes[:default_rights] = rights
  end

  def default_rights
    @changes[:default_rights]
  end

  def default_rights_changed?
    @changes.key?(:default_rights)
  end

  def title=(title)
    @changes[:title] = title&.strip
  end

  def title
    @changes[:title]
  end

  def title_changed?
    @changes.key?(:title)
  end

  def default_workflow=(workflow)
    @changes[:default_workflow] = workflow
  end

  def default_workflow
    @changes[:default_workflow]
  end

  def default_workflow_changed?
    @changes.key?(:default_workflow)
  end

  def permissions=(permissions)
    @changes[:permissions] = permissions
  end

  def permissions
    @changes[:permissions]
  end

  def permissions_changed?
    @changes.key?(:permissions)
  end

  # Does the user want to create a new default collection
  def collection_radio=(val)
    @changes[:collection_radio] = val
  end

  def collection_radio
    @changes[:collection_radio]
  end

  def collections_for_registration=(val)
    @changes[:collections_for_registration] = val
  end

  def collections_for_registration
    @changes[:collections_for_registration] || {}
  end

  # These attributes get passed to the CollectionForm
  def collection=(val)
    @changes[:collection] = val
  end

  def collection
    @changes[:collection]
  end
end
