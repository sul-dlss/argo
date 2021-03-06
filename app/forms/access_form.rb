# frozen_string_literal: true

# A form object for updating the rights on an item
# @abstract
class AccessForm
  extend ActiveModel::Naming
  # @param [Cocina::Models::DRO, Cocina::Models::Collection] model
  # @param [String] the default rights to assign to the object
  # must be one of the options in Constants::COLLECTION_RIGHTS_OPTIONS or Constants::REGISTRATION_RIGHTS_OPTIONS depending on form
  # (used to be one of the keys in Dor::RightsMetadataDS::RIGHTS_TYPE_CODES in the now de-coupled dor-services gem)
  def initialize(model, default_rights: nil)
    @model = model
    @default_rights = default_rights || 'citation-only'
  end

  # @param [HashWithIndifferentAccess] params the values from the form
  # @option params [String] :rights the rights representation from the form
  # must be one of the options in Constants::COLLECTION_RIGHTS_OPTIONS or Constants::REGISTRATION_RIGHTS_OPTIONS depending on form
  # (used to be one of the keys in Dor::RightsMetadataDS::RIGHTS_TYPE_CODES in the now de-coupled dor-services gem)
  def validate(params)
    rights = params[:rights]
    # valid_rights_options is implemented by concrete class.
    return false unless valid_rights_options.include?(rights)

    @rights = rights
    true
  end

  # This is the default rights selection
  def rights
    @rights ||= derive_rights_from_cocina
  end

  def rights_list
    @rights_list ||= rights_list_for_apo
  end

  def save
    sync
    Dor::Services::Client.object(model.externalIdentifier).update(params: model)
    Argo::Indexer.reindex_pid_remotely(model.externalIdentifier)
  end

  private

  attr_reader :model

  def derive_rights_from_cocina
    rights = if @model.access.readLocation
               "loc:#{@model.access.readLocation}"
             else
               @model.access.access
             end

    rights += '-nd' if @model.access.download == 'none' && !%w[citation-only dark].include?(@model.access.access)
    rights
  end
end
