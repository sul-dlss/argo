# frozen_string_literal: true

# A form object for updating the rights on an item
class AccessForm
  extend ActiveModel::Naming

  # @param [Cocina::Models::DRO]
  def initialize(model, apo)
    @model = model
    @apo = apo
  end

  def rights
    @rights ||= derive_rights_from_cocina
  end

  def rights_list
    @rights_list ||= rights_list_for_apo
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

  def rights_list_for_apo
    default_opt = @apo.default_rights || 'citation-only'

    # iterate through the default version of the rights list.  if we found a default option
    # selection, label it in the UI text and key it as 'default' (instead of its own name).  if
    # we didn't find a default option, we'll just return the default list of rights options with no
    # specified selection.
    result = []
    Constants::REGISTRATION_RIGHTS_OPTIONS.each do |val|
      result << if default_opt == val[1]
                  ["#{val[0]} (APO default)", val[1]]
                else
                  val
                end
    end
    result
  end
end
