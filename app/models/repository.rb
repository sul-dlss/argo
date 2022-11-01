# frozen_string_literal: true

class Repository
  # @param [String] id the identifier for the item to be found
  # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy,NilModel] cocina model instance corresponding to the given druid
  # @raise [Dor::Services::Client::NotFoundResponse] when dor-services-app cannot find the given object ID
  def self.find(id)
    raise ArgumentError, "Missing identifier" unless id

    maybe_load_cocina(id)
  end

  # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy,NilModel] the updated cocina model instance
  # @raises [Dor::Services::Client::BadRequestError] when the server doesn't accept the request
  def self.store(cocina_object)
    object_client = Dor::Services::Client.object(cocina_object.externalIdentifier)
    object_client.update(params: cocina_object)
  end

  # Currently we know that not all objects are Cocina compliant, this ensures that we can at least
  # receive some object and so, at least administrators can be authorized to operate on it.
  # See: https://argo.stanford.edu/catalog?f[data_quality_ssim][]=Cocina+conversion+failed
  # @return [Cocina::Models::DRO,NilModel]
  def self.maybe_load_cocina(druid)
    object_client = Dor::Services::Client.object(druid)
    object_client.find
  rescue Dor::Services::Client::UnexpectedResponse
    NilModel.new(druid)
  end
end
