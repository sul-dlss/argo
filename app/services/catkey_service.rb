# frozen_string_literal: true

# Updates the catkey on an object by calling the dor-services-app api
class CatkeyService
  def self.update(cocina_model, object_client, new_catkey)
    updated_identification = cocina_model.identification.new(
      catalogLinks: [{ catalog: 'symphony', catalogRecordId: new_catkey }]
    )
    updated = cocina_model.new(identification: updated_identification)
    object_client.update(params: updated)
  end
end
