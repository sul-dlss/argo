# frozen_string_literal: true

# Calls the workflow service to determine the state of an object.
# Used by AJAX requests mainly from the action buttons (check_url)
class WorkflowServiceController < ApplicationController
  ##
  # Is a document closeable?
  def closeable
    @status = check_if_can_close_version
    render json: @status
  end

  ##
  # Is a document openable?
  def openable
    @status = check_if_can_open_version
    render json: @status
  end

  ##
  # Has an object been published?
  def published
    @status = check_if_published
    render json: @status
  end

  ##
  # Has an object been submitted?
  def submitted
    @status = check_if_submitted
    render json: @status
  end

  ##
  # Has an object been accessioned?
  def accessioned
    @status = check_if_accessioned
    render json: @status
  end

  private

  def get_lifecycle(task)
    Dor::Config.workflow.client.lifecycle('dor', params[:pid], task)
  end

  def active_lifecycle(task, druid:, version:)
    Dor::Config.workflow.client.active_lifecycle('dor', druid, task, version: version)
  end

  ##
  # Ported over logic from app/helpers/dor_object_helper.rb#LN119
  # @return [Boolean]
  def check_if_published
    return true if get_lifecycle('published')

    false
  end

  ##
  # Ported over logic from app/helpers/dor_object_helper.rb#LN126
  # @return [Boolean]
  def check_if_submitted
    return true if get_lifecycle('submitted')

    false
  end

  ##
  # Ported over logic from app/helpers/dor_object_helper.rb#LN133
  # @return [Boolean]
  def check_if_accessioned
    return true if get_lifecycle('accessioned')

    false
  end

  ##
  # Ported over logic from app/helpers/dor_object_helper.rb#LN167
  # @return [Boolean]
  def check_if_can_close_version
    version = Dor::Services::Client.object(params[:pid]).version.current
    return true if active_lifecycle('opened', druid: params[:pid], version: version) &&
                   !active_lifecycle('submitted', druid: params[:pid], version: version)

    false
  end

  ##
  # Ported over logic from app/helpers/dor_object_helper.rb#LN160
  # @return [Boolean]
  def check_if_can_open_version
    return false unless check_if_accessioned

    version = Dor::Services::Client.object(params[:pid]).version.current
    return false if active_lifecycle('submitted', druid: params[:pid], version: version)
    return false if active_lifecycle('opened', druid: params[:pid], version: version)

    true
  end
end
