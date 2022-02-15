# frozen_string_literal: true

module Types
  include Dry.Types()
end

class StateService
  # NOTE: each of these states must have a corresponding view with the same name in app/views/workflow_service: the names are used to render lock/unlock icons/links
  STATES = Types::Symbol.enum(:unlock, :lock, :lock_inactive, :unlock_inactive)
  UNLOCKED_STATES = [STATES[:unlock], STATES[:unlock_inactive]].freeze

  def initialize(pid, version:)
    @pid = pid
    @version = version
  end

  def allows_modification?
    UNLOCKED_STATES.include? object_state
  end

  ##
  # Ported over logic from app/helpers/dor_object_helper.rb#LN119
  # @return [Boolean]
  def published?
    lifecycle('published') ? true : false
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def object_state
    # This item is currently unlocked and can be edited and moved to a locked state
    return STATES[:unlock] if !active_assembly_wf? && opened? && !submitted?

    # This item is currently locked and cannot be edited, and can be moved to an unlocked state
    return STATES[:lock] if accessioned? && !submitted? && !opened?

    # This item is being accessioned, so is locked but cannot currently be unlocked or edited
    return STATES[:lock_inactive] if submitted? || opened?

    # This item is registered, so it can be edited, but cannot currently be moved to a locked state
    STATES[:unlock_inactive]
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity

  private

  attr_reader :pid, :version

  def lifecycle(task)
    workflow_client.lifecycle(druid: pid, milestone_name: task)
  end

  def active_lifecycle(task)
    workflow_client.active_lifecycle(druid: pid, milestone_name: task, version: version)
  end

  def opened?
    @opened ||= active_lifecycle('opened')
  end

  def submitted?
    @submitted ||= active_lifecycle('submitted')
  end

  ##
  # Ported over logic from app/helpers/dor_object_helper.rb#LN133
  # @return [Boolean]
  def accessioned?
    @accessioned ||= lifecycle('accessioned') ? true : false
  end

  def active_assembly_wf?
    @active_assembly_wf ||= workflow_client.workflow_status(druid: pid, workflow: 'assemblyWF', process: 'accessioning-initiate') == 'waiting'
  end

  def workflow_client
    @workflow_client ||= WorkflowClientFactory.build
  end
end
