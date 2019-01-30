# frozen_string_literal: true

# Represents the status of an object doing a workflow process
class WorkflowProcessStatus
  # @params [WorkflowStatus] parent
  # @params [String] name the name of the processing step
  # @params [Hash] attributes
  def initialize(parent:, name:, **attributes)
    @parent = parent
    @attributes = attributes
    @attributes[:name] = name
  end

  def name
    @attributes[:name].presence
  end

  def status
    @attributes[:status].presence
  end

  def datetime
    @attributes[:datetime].presence
  end

  def elapsed
    @attributes[:elapsed].presence
  end

  def attempts
    @attributes[:attempts].presence
  end

  def lifecycle
    @attributes[:lifecycle].presence
  end

  def note
    @attributes[:note].presence
  end

  delegate :pid, :workflow_name, to: :parent

  private

  attr_reader :parent
end
