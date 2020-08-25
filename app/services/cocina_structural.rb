# frozen_string_literal: true

class CocinaStructural
  # @param structural [Cocina::Models::DROStructural] the DRO structural metadata to modify
  # @param rights [String] the rights representation from the form (must be one of the keys in Dor::RightsMetadataDS::RIGHTS_TYPE_CODES, or 'default')
  # @return [Hash<Symbol,String>] a hash representing a subset of the Structural subschema of the Cocina model
  def self.from_form_value(rights, structural)
    # Convert to hash so we can mutate it
    structural.to_h.tap do |structure_hash|
      if rights == 'dark' && structural&.contains&.any?
        structure_hash[:contains].each do |fileset|
          fileset[:structural][:contains].each do |file|
            # Ensure files attached to dark objects are neither published nor shelved
            file[:access].merge!(access: 'dark')
            file[:administrative].merge!(shelve: false)
          end
        end
      end
    end
  end
end
