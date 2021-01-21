# frozen_string_literal: true

# This stands in place of a Cocina model, when the server returns an UnexpectedResponse
class NilModel
  def initialize(pid)
    @pid = pid
  end

  # rubocop:disable Naming/MethodName
  def externalIdentifier
    @pid
  end
  # rubocop:enable Naming/MethodName

  def administrative
    NilAdministrative.new
  end

  def access
    Cocina::Models::DROAccess.new
  end

  def collection?
    false
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
