# frozen_string_literal: true

module CreatesBulkActions
  extend ActiveSupport::Concern

  included do
    class_attribute :action_type
  end

  def new; end

  def create
    bulk_action = BulkAction.new(user: current_user, action_type: action_type, description: params[:description])

    if bulk_action.save
      bulk_action.enqueue_job(job_params)

      # strip the CSRF token, and the parameters that happened to be in the bulk job creation form
      # this can be removed when this is resolved: https://github.com/projectblacklight/blacklight/issues/2683
      search_state_subset = search_state.to_h.except(:authenticity_token, :druids, :druids_only, :description)
      path_params = Blacklight::Parameters.sanitize(search_state_subset)
      redirect_to bulk_actions_path(path_params), status: :see_other, notice: success_message
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def success_message
    "#{action_type.underscore.humanize} was successfully created."
  end

  # NOTE: It's important that this is a HashWithIndifferentAccess, because the jobs are expecting that interface
  def job_params
    { druids: identifiers, groups: current_user.groups }.with_indifferent_access
  end

  # add druid: prefix to list of druids if it doesn't have it yet
  def identifiers
    return [] if params[:druids].blank?

    params[:druids].split.map { |druid| Druid.new(druid).with_namespace }
  end
end
