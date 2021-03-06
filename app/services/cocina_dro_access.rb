# frozen_string_literal: true

# This transcodes the access from the item set rights form and registration form to Cocina DROAccess schema
class CocinaDroAccess
  extend Dry::Monads[:maybe]

  # @param [String] rights the rights representation from the form (must be one of the keys in Constants::REGISTRATION_RIGHTS_OPTIONS, or 'default')
  # @return [Maybe<Hash<Symbol,String>>] a hash representing a subset of the Access subschema of the Cocina model
  def self.from_form_value(rights)
    # Default only appears on the registration form, not the update form.
    return None() if rights == 'default'

    data = if rights == 'cdl-stanford-nd'
             {
               access: 'stanford',
               download: 'none',
               readLocation: nil,
               controlledDigitalLending: true
             }
           elsif rights.end_with?('-nd') || %w[dark citation-only].include?(rights)
             {
               access: rights.delete_suffix('-nd'),
               download: 'none',
               readLocation: nil,
               controlledDigitalLending: false
             }
           elsif rights.start_with?('loc:')
             {
               access: 'location-based',
               readLocation: rights.delete_prefix('loc:'),
               download: 'location-based',
               controlledDigitalLending: false
             }
           else
             {
               access: rights,
               download: rights,
               readLocation: nil,
               controlledDigitalLending: false
             }
           end
    Some(data)
  end
end
