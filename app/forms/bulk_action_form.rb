# frozen_string_literal: true

# This models the values set from the bulk action form
class BulkActionForm < BaseForm
  def initialize(model, groups:)
    super(model)
    @groups = groups
  end

  def save
    sync
    BulkActionPersister.persist(self)
  end

  def sync
    model.attributes = params.except(:pids, :groups, :manage_release, :set_governing_apo, :manage_catkeys, :prepare, :create_virtual_objects)
    @pids = pids_with_prefix
    @create_virtual_objects = params[:create_virtual_objects]
    @manage_catkeys = params[:manage_catkeys]
    @manage_release = params[:manage_release]
    @prepare = params[:prepare]
    @set_governing_apo = params[:set_governing_apo]
  end

  attr_reader :groups, :pids, :create_virtual_objects, :manage_catkeys, :manage_release, :prepare, :set_governing_apo

  delegate :action_type, :description, to: :model

  private

  # add druid: prefix to list of pids if it doesn't have it yet
  def pids_with_prefix
    pids = params[:pids]
    return pids if pids.blank?

    pids.split.flatten.map { |pid| pid.start_with?('druid:') ? pid : "druid:#{pid}" }.join("\n")
  end
end
