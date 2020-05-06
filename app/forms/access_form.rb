# frozen_string_literal: true

# A form object for updating the rights on an item
class AccessForm
  extend ActiveModel::Naming

  # @param [Cocina::Models::DRO]
  def initialize(model)
    @model = model
  end

  def rights
    @rights ||= derive_rights_from_cocina
  end

  private

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
end
