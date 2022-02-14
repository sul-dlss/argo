# frozen_string_literal: true

class StateService
  def initialize(pid, version:)
    @pid = pid
    @version = version
  end

  def allows_modification?
    %i[unlock unlock_inactive].include? object_state
  end

  ##
  # Ported over logic from app/helpers/dor_object_helper.rb#LN119
  # @return [Boolean]
  def published?
    get_lifecycle('published') ? true : false
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def object_state
    # This item is closeable, display a working unlock button
    return :unlock if !active_assembly_wf? && opened? && !submitted?

    # This item is openable, display lock and action possible.
    return :lock if accessioned? && !submitted? && !opened?

    # This item is being accessioned, display lock but no action
    return :lock_inactive if submitted? || opened?

    # This item is registered, display unlock, but no action
    :unlock_inactive
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity

  private

  attr_reader :pid, :version

  def get_lifecycle(task)
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
    @accessioned ||= get_lifecycle('accessioned') ? true : false
  end

  def active_assembly_wf?
    @active_assembly_wf ||= workflow_client.workflow_status(druid: pid, workflow: 'assemblyWF', process: 'accessioning-initiate') == 'waiting'
  end

  def workflow_client
    @workflow_client ||= WorkflowClientFactory.build
  end
end
