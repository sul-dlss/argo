# frozen_string_literal: true

class Repository
  class NotCocina < StandardError; end

  def self.find(id)
    raise ArgumentError, 'Missing identifier' unless id

    cocina = maybe_load_cocina(id)
    raise NotCocina, 'Unable to retrieve the cocina model' if cocina.is_a? NilModel

    klass = if cocina.collection?
              Collection
            elsif cocina.admin_policy?
              AdminPolicy
            else
              Item
            end
    @item = klass.new(cocina)
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
