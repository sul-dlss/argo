# frozen_string_literal: true

class CocinaAccess
  # @param [String] the rights representation from the form (must be one of the keys in Dor::RightsMetadataDS::RIGHTS_TYPE_CODES, or 'default')
  # @return [Hash<Symbol,String>] a hash representing the Access subschema of the Cocina model
  def self.from_form_value(rights)
    return {} if rights == 'default'

    model_params = if rights.end_with?('-nd') || %w[dark citation-only].include?(rights)
                     {
                       access: rights.delete_suffix('-nd'),
                       download: 'none'
                     }
                   elsif rights.start_with?('loc:')
                     {
                       access: 'location-based',
                       readLocation: rights.delete_prefix('loc:'),
                       download: 'location-based'
                     }
                   else
                     {
                       access: rights,
                       download: rights
                     }
                   end

    { access: model_params }
  end
end
