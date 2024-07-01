# frozen_string_literal: true

class Repository
  # @param [String] id the identifier for the item to be found
  # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] cocina model instance corresponding to the given druid
  # @raise [Dor::Services::Client::NotFoundResponse] when dor-services-app cannot find the given object ID
  def self.find(id)
    raise ArgumentError, 'Missing identifier' unless id

    object_client = Dor::Services::Client.object(id)
    object_client.find
  end

  # @param [String] id the identifier for the item to be found
  # @param [Boolean] structural whether to return a structural model
  # @return [Cocina::Models::DROLite,Cocina::Models::CollectionLite,Cocina::Models::AdminPolicyLite] cocina model instance corresponding to the given druid
  # @raise [Dor::Services::Client::NotFoundResponse] when dor-services-app cannot find the given object ID
  def self.find_lite(id, structural: true)
    raise ArgumentError, 'Missing identifier' unless id

    object_client = Dor::Services::Client.object(id)
    object_client.find_lite(structural:)
  end

  # @param [String] id the identifier for the item to be found
  # @param [String] user_version the user version to be found
  # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] cocina model instance corresponding to the given druid
  # @raise [Dor::Services::Client::NotFoundResponse] when dor-services-app cannot find the requested user version
  def self.find_user_version(id, user_version)
    raise ArgumentError, 'Missing identifier' unless id
    raise ArgumentError, 'Missing user_version' unless user_version

    object_client = Dor::Services::Client.object(id)
    object_client.user_version.find(user_version)
  end

  # @return [Cocina::Models::DRO,Cocina::Models::Collection,Cocina::Models::AdminPolicy] the updated cocina model instance
  # @raises [Dor::Services::Client::UnexpectedResponse] when an error occurs updating the object
  def self.store(cocina_object)
    object_client = Dor::Services::Client.object(cocina_object.externalIdentifier)
    object_client.update(params: cocina_object)
  end
end
