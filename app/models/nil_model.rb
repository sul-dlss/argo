# frozen_string_literal: true

# This stands in place of a Cocina model, when the server returns an UnexpectedResponse
class NilModel
  def initialize(druid)
    @druid = druid
  end

  def externalIdentifier
    @druid
  end

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
    def releaseTags
      []
    end
  end
end
