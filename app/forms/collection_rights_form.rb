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
    updated_access = model.access.new(access_additions.value!)

    @model = model.new(access: updated_access)
  end

  # all the rights except CDL
  def rights_list
    super.filter { |i| i.last != 'cdl-stanford-nd' }
  end

  private

  # Used by AccessForm#validate
  def valid_rights_options
    Constants::REGISTRATION_RIGHTS_OPTIONS.map(&:last).without('cdl-stanford-nd')
  end
end
