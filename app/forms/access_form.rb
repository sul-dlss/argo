# frozen_string_literal: true

# A form object for updating the rights on an item
# @abstract
class AccessForm
  extend ActiveModel::Naming
  # @param [Cocina::Models::DRO, Cocina::Models::Collection] model
  # @param [String] the default rights to assign to the object, from Constants::REGISTRATION_RIGHTS_OPTIONS (which is defined as RIGHTS_TYPE_CODES in dor-services)
  def initialize(model, default_rights: nil)
    @model = model
    @default_rights = default_rights || 'citation-only'
  end

  # @param [HashWithIndifferentAccess] params the values from the form
  # @option params [String] :rights the rights representation from the form (must be one of the keys in Dor::RightsMetadataDS::RIGHTS_TYPE_CODES, or 'default')
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
             elsif @model.access.access == 'citation-only'
               'none' # TODO: we could remove this if we switch to REGISTRATION_RIGHTS_OPTIONS from DEFAULT_RIGHTS_OPTIONS
             else
               @model.access.access
             end

    rights += '-nd' if @model.access.download == 'none' && !%w[citation-only dark].include?(@model.access.access)
    rights
  end

  def rights_list_for_apo
    # iterate through the default version of the rights list.  if we found a default option
    # selection, label it in the UI text and key it as 'default' (instead of its own name).  if
    # we didn't find a default option, we'll just return the default list of rights options with no
    # specified selection.
    result = []
    Constants::REGISTRATION_RIGHTS_OPTIONS.each do |val|
      result << if @default_rights == val[1]
                  ["#{val[0]} (APO default)", val[1]]
                else
                  val
                end
    end
    result
  end
end
