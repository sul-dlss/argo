# frozen_string_literal: true

# Calls the workflow service to determine the state of an object.
# Used by AJAX requests mainly from the action buttons (check_url)
class WorkflowServiceController < ApplicationController
  ##
  # Draw the lock/unlock button
  def lock
    version = Dor::Services::Client.object(params[:id]).version.current
    opened = active_lifecycle('opened', druid: params[:id], version: version)
    submitted = active_lifecycle('submitted', druid: params[:id], version: version)
    template = find_template(opened, submitted)

    render template, locals: { id: params[:id] }
  end

  ##
  # Has an object been published?
  def published
    @status = check_if_published
    render json: @status
  end

  private

  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def find_template(opened, submitted)
    # This item is closeable, display a working unlock button
    return 'unlock' if !active_assembly_wf? && opened && !submitted

    # This item is openable, display lock and action possible.
    return 'lock' if accessioned? && !submitted && !opened

    # This item is being accessioned, display lock but no action
    return 'lock_inactive' if submitted || opened

    # This item is registered, display unlock, but no action
    'unlock_inactive'
  end
  # rubocop:enable Metrics/PerceivedComplexity
  # rubocop:enable Metrics/CyclomaticComplexity

  def get_lifecycle(task)
    workflow_client.lifecycle(druid: params[:id], milestone_name: task)
  end

  def active_lifecycle(task, druid:, version:)
    workflow_client.active_lifecycle(druid: druid, milestone_name: task, version: version)
  end

  ##
  # Ported over logic from app/helpers/dor_object_helper.rb#LN119
  # @return [Boolean]
  def check_if_published
    return true if get_lifecycle('published')

    false
  end

  ##
  # Ported over logic from app/helpers/dor_object_helper.rb#LN133
  # @return [Boolean]
  def accessioned?
    get_lifecycle('accessioned') ? true : false
  end

  def active_assembly_wf?
    workflow_client.workflow_status(druid: params[:id], workflow: 'assemblyWF', process: 'accessioning-initiate') == 'waiting'
  end

  def workflow_client
    @workflow_client ||= WorkflowClientFactory.build
  end
end
