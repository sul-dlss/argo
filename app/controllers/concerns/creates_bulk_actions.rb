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

      redirect_to bulk_actions_path, status: :see_other, notice: success_message
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

    params[:druids].split.map { |druid| druid.start_with?('druid:') ? druid : "druid:#{druid}" }
  end
end
