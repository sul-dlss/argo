# frozen_string_literal: true

# Calls the workflow service to determine the state of an object.
# Used by AJAX requests mainly from the action buttons (check_url)
class WorkflowServiceController < ApplicationController
  before_action :load_cocina

  ##
  # Draw the lock/unlock button depending on which state the object is in
  def lock
    render StateService.new(@cocina).object_state, locals: {id: params[:id]}
  end

  ##
  # Has an object been published?
  def published
    @status = StateService.new(@cocina).published?
    render json: @status
  end

  private

  def load_cocina
    @cocina = Repository.find(params[:id])
  end
end
