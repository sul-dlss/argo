# frozen_string_literal: true

class Repository
  # @param [String] id the identifier for the item to be found
  # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy,NilModel] cocina model instance corresponding to the given druid
  # @raise [Dor::Services::Client::NotFoundResponse] when dor-services-app cannot find the given object ID
  def self.find(id)
    raise ArgumentError, "Missing identifier" unless id

    object_client = Dor::Services::Client.object(id)
    object_client.find
  rescue Dor::Services::Client::UnexpectedResponse
    NilModel.new(id)
  end

  # @param [String] id the identifier for the item to be found
  # @param [Boolean] structural whether to return a structural model
  # @return [Cocina::Models::DROLite,Cocina::Models::CollectionLite,Cocina::Models::AdminPolicyLite,NilModel] cocina model instance corresponding to the given druid
  # @raise [Dor::Services::Client::NotFoundResponse] when dor-services-app cannot find the given object ID
  def self.find_lite(id, structural: true)
    raise ArgumentError, "Missing identifier" unless id

    object_client = Dor::Services::Client.object(id)
    object_client.find_lite(structural: structural)
  rescue Dor::Services::Client::UnexpectedResponse
    NilModel.new(id)
  end

  # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy,NilModel] the updated cocina model instance
  # @raises [Dor::Services::Client::BadRequestError] when the server doesn't accept the request
  def self.store(cocina_object)
    object_client = Dor::Services::Client.object(cocina_object.externalIdentifier)
    object_client.update(params: cocina_object)
  end
end
