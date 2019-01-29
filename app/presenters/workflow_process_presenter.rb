# frozen_string_literal: true

# Shows a single step in a workflow for a single object/version
class WorkflowProcessPresenter
  def initialize(name:, **attributes)
    @attributes = attributes
    @attributes[:name] = name
  end

  def name
    @attributes[:name]
  end

  def status
    @attributes[:status]
  end

  def datetime
    @attributes[:datetime]
  end

  def elapsed
    return unless @attributes[:elapsed]

    format('%.3f', @attributes[:elapsed].to_f)
  end

  def attempts
    @attributes[:attempts]
  end

  def lifecycle
    @attributes[:lifecycle]
  end

  def note
    @attributes[:note]
  end
end
