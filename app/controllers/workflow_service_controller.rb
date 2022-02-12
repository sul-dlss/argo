# frozen_string_literal: true

# Calls the workflow service to determine the state of an object.
# Used by AJAX requests mainly from the action buttons (check_url)
class WorkflowServiceController < ApplicationController
  ##
  # Draw the lock/unlock button
  def lock
    render StateService.new(params[:id]).object_state.to_s, locals: { id: params[:id] }
  end

  ##
  # Has an object been published?
  def published
    @status = StateService.new(params[:id]).published?
    render json: @status
  end
end
