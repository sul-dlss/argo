# frozen_string_literal: true

module Types
  include Dry.Types()
end

class StateService
  # NOTE: each of these states must have a corresponding view with the same name in app/views/workflow_service: the names are used to render lock/unlock icons/links
  STATES = Types::Symbol.enum(:unlock, :lock, :lock_inactive, :unlock_inactive, :lock_assembling)

  def initialize(cocina)
    @druid = cocina.externalIdentifier
    @version = cocina.version
  end

  def object_state
    # This item is currently unlocked and can be edited and moved to a locked state
    return STATES[:unlock] if open? && closeable?

    # This item is currently locked and cannot be edited, and can be moved to an unlocked state
    return STATES[:lock] if closed? && openable?

    # This item is being accessioned, so is locked but cannot currently be unlocked or edited
    return STATES[:lock_inactive] if closed? && !openable?

    # This item is being assembled or text extracted, so is locked but cannot currently be unlocked or edited
    return STATES[:lock_assembling] if assembling? || text_extracting?

    # This item is registered, so it can be edited, but cannot currently be moved to a locked state
    STATES[:unlock_inactive] # if open? && !closeable?
  end

  private

  attr_reader :druid, :version

  def version_service
    @version_service ||= VersionService.new(druid:)
  end

  delegate :open?, :openable?, :closed?, :closeable?, :assembling?, :text_extracting?, :version, to: :version_service
end
