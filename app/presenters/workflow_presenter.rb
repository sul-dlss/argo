# frozen_string_literal: true

class WorkflowPresenter
  # @param [Object] view the rails view context
  # @param [WorkflowStatus] workflow_status
  # @param [Cocina::Models::DRO,Cocina::Models::Collection] cocina_object the repository object that the workflow is about
  def initialize(view:, workflow_status:, cocina_object:)
    @view = view
    @workflow_status = workflow_status
    @cocina_object = cocina_object
  end

  delegate :druid, :workflow_name, to: :workflow_status

  # @return [Array] all the steps in the workflow definition
  def processes
    workflow_status.process_statuses
  end

  attr_reader :cocina_object

  private

  attr_reader :workflow_status, :view
end
