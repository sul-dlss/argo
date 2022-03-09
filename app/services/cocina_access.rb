# frozen_string_literal: true

# This transcodes the access from the collection forms to Cocina Access schema
class CocinaAccess
  extend Dry::Monads[:maybe]

  # @param [String] the rights representation from the form (must be one of the keys in Constants::COLLECTION_RIGHTS_OPTIONS, or 'default')
  # @return [Maybe<Hash<Symbol,String>>] a hash representing a subset of the Access subschema of the Cocina model
  def self.from_form_value(rights)
    # Default only appears on the registration form, not the update form.
    return None() if rights == 'default'

    data = if rights.end_with?('-nd') || %w[dark citation-only].include?(rights)
             {
               view: rights.delete_suffix('-nd')
             }
           elsif rights.start_with?('loc:')
             {
               view: 'location-based',
               location: rights.delete_prefix('loc:')
             }
           else
             {
               view: rights
             }
           end
    Some(data)
  end
end
