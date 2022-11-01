# frozen_string_literal: true

class Druid
  def initialize(identifier_or_cocina)
    identifier = identifier_or_cocina.respond_to?(:externalIdentifier) ? identifier_or_cocina.externalIdentifier : identifier_or_cocina
    @identifier = identifier.start_with?("druid:") ? identifier : "druid:#{identifier}"
  end

  def with_namespace
    @identifier
  end

  def without_namespace
    @identifier.delete_prefix("druid:")
  end
end
