# frozen_string_literal: true

# This stands in place of a Cocina model, when the server returns an UnexpectedResponse
class NilModel
  def initialize(druid)
    @druid = druid
  end

  # rubocop:disable Naming/MethodName
  def externalIdentifier
    @druid
  end
  # rubocop:enable Naming/MethodName

  def version
    1
  end

  def administrative
    NilAdministrative.new
  end

  def access
    Cocina::Models::DROAccess.new
  end

  def structural
    Cocina::Models::DROStructural.new
  end

  def collection?
    false
  end

  def to_h
    {}
  end

  # This stands in for the administrative metadata
  class NilAdministrative
    # rubocop:disable Naming/MethodName
    def releaseTags
      []
    end
    # rubocop:enable Naming/MethodName
  end
end
