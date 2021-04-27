# frozen_string_literal: true

# This represents the form in the modal on the item page that appears when you
# click "Set rights" in the sidebar
class DroRightsForm < AccessForm
  # @param [Cocina::Models::DRO] model
  # @param [String] default_rights the default rights that the APO has set. Used for labeling the select list of options
  def initialize(model, default_rights: nil)
    super
  end

  # Copy the settings to the model
  def sync
    access_additions = CocinaDroAccess.from_form_value(rights)
    updated_access = model.access.new(access_additions.value!)
    updated_structural = model.structural.new(structural_additions(access_additions.value!))
    @model = model.new(access: updated_access, structural: updated_structural)
  end

  private

  # @param structural [Cocina::Models::DROStructural] the DRO structural metadata to modify
  # @return [Hash<Symbol,String>] a hash representing a subset of the Structural subschema of the Cocina model
  def structural_additions(new_object_access)
    # Convert to hash so we can mutate it
    structure_hash = model.structural.to_h
    Array(structure_hash[:contains]).each do |fileset|
      fileset[:structural][:contains].each do |file|
        case rights
        when 'dark'
          # Ensure files attached to dark objects are neither published nor shelved
          file[:access].merge!(access: 'dark', download: 'none', controlledDigitalLending: false, readLocation: nil)
          file[:administrative].merge!(publish: false)
          file[:administrative].merge!(shelve: false)
        when 'citation-only'
          file[:access].merge!(access: 'dark', download: 'none', controlledDigitalLending: false, readLocation: nil)
        else
          file[:access].merge!(new_object_access)
        end
      end
    end
    structure_hash
  end

  # Used by AccessForm#validate
  def valid_rights_options
    Constants::REGISTRATION_RIGHTS_OPTIONS.map(&:last)
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
