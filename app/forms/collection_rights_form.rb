# frozen_string_literal: true

# This represents the form in the modal on the item page that appears when you
# click "Set rights" in the sidebar
class CollectionRightsForm < AccessForm
  # @param [Cocina::Models::Collection] model
  # @param [String] default_rights the default rights that the APO has set. Used for labeling the select list of options
  def initialize(model, default_rights: nil)
    super
  end

  def sync
    access_additions = CocinaAccess.from_form_value(rights)
    updated_access = model.access.new(access_additions.value!.except(:download, :location, :controlledDigitalLending))

    @model = model.new(access: updated_access)
  end

  private

  # Used by AccessForm#validate
  def valid_rights_options
    Constants::COLLECTION_RIGHTS_OPTIONS.map(&:last)
  end

  def derive_rights_from_cocina
    @model.access.view
  end

  def rights_list_for_apo
    # iterate through the default version of the rights list.  if we found a default option
    # selection, label it in the UI text and key it as 'default' (instead of its own name).  if
    # we didn't find a default option, we'll just return the default list of rights options with no
    # specified selection.
    result = []
    Constants::COLLECTION_RIGHTS_OPTIONS.each do |val|
      result << if @default_rights == val[1]
                  ["#{val[0]} (APO default)", val[1]]
                else
                  val
                end
    end
    result
  end
end
