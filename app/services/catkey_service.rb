# frozen_string_literal: true

# Updates the catkey on an object by calling the dor-services-app api
class CatkeyService
  def self.update(druid, new_catkey)
    object_client = Dor::Services::Client.object(druid)
    dro = object_client.find
    updated_identification = dro.identification.new(
      catalogLinks: [{ catalog: 'symphony', catalogRecordId: new_catkey }]
    )
    updated = dro.new(identification: updated_identification)
    object_client.update(params: updated)
  end
end
