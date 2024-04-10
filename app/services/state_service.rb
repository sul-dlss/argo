# frozen_string_literal: true

module Types
  include Dry.Types()
end

class StateService
  # NOTE: each of these states must have a corresponding view with the same name in app/views/workflow_service: the names are used to render lock/unlock icons/links
  STATES = Types::Symbol.enum(:unlock, :lock, :lock_inactive, :unlock_inactive)

  def initialize(cocina)
    @druid = cocina.externalIdentifier
    @version = cocina.version
  end

  def object_state
    # This item is currently unlocked and can be edited and moved to a locked state
    # In Argo, the user can't close a version if it's the first version
    # (though, technically, the version is closeeable).
    return STATES[:unlock] if open? && closeable? && !first_version?

    # This item is currently locked and cannot be edited, and can be moved to an unlocked state
    return STATES[:lock] if closed? && openable?

    # This item is being accessioned, so is locked but cannot currently be unlocked or edited
    return STATES[:lock_inactive] if closed? && !openable?

    # This item is registered, so it can be edited, but cannot currently be moved to a locked state
    STATES[:unlock_inactive] # if open? && !closeable?
  end

  private

  attr_reader :druid, :version

  def version_service
    @version_service ||= VersionService.new(druid:)
  end

  delegate :open?, :openable?, :closed?, :closeable?, :version, to: :version_service

  def first_version?
    version == 1
  end
end
