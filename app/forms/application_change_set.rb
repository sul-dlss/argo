# frozen_string_literal: true

# A superclass for the change sets that handles forms backed by Cocina objects
class ApplicationChangeSet < Reform::Form
  # needed for generating the update route
  def to_param
    model.externalIdentifier
  end

  def persisted?
    model.present?
  end
end
