# frozen_string_literal: true

class VersionsController < ApplicationController
  before_action :load_and_authorize_resource

  def open_ui
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def close_ui
    versions = Dor::Services::Client.object(params[:item_id]).version.inventory
    # We do the reverse here, because it's possible there is no previous version
    current_version, previous_version = versions.sort_by(&:versionId).last(2).reverse
    @description = current_version.message
    @tag = current_version.tag

    # figure out which part of the version number changed when opening the item
    # for versioning, so that the form can pre-select the correct significance level
    changed_significance = which_significance_changed(@tag, previous_version.tag)
    @significance_selected = {}
    %i[major minor admin].each do |significance|
      @significance_selected[significance] = (changed_significance == significance)
    end

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def open
    VersionService.open(identifier: @cocina_object.externalIdentifier,
                        significance: params[:significance],
                        description: params[:description],
                        opening_user_name: current_user.to_s)
    msg = "#{@cocina_object.externalIdentifier} is open for modification!"
    redirect_to solr_document_path(params[:item_id]), notice: msg
    Argo::Indexer.reindex_pid_remotely(@cocina_object.externalIdentifier)
  rescue StandardError => e
    raise e unless e.to_s == 'Object net yet accessioned'

    render status: :internal_server_error, plain: 'Object net yet accessioned'
    nil
  end

  # as long as this isn't a bulk operation, and we get non-nil significance and description
  # values, update those fields on the version metadata datastream
  def close
    VersionService.close(
      identifier: @cocina_object.externalIdentifier,
      description: params[:description],
      significance: params[:significance],
      user_name: current_user.to_s
    )
    msg = "Version #{@cocina_object.version} of #{@cocina_object.externalIdentifier} has been closed!"
    redirect_to solr_document_path(params[:item_id]), notice: msg
    Argo::Indexer.reindex_pid_remotely(@cocina_object.externalIdentifier)
  end

  private

  # Given two instances of VersionTag, find the most significant difference
  # between the two (return nil if either one is nil or if they're the same)
  # @param [String,NilClass] current_tag current version tag
  # @param [String,NilClass] previous_tag prior version tag
  # @return [Symbol] :major, :minor, :admin or nil
  def which_significance_changed(current_tag, previous_tag)
    return nil if current_tag.nil? || previous_tag.nil?

    cur_version_tag = Dor::VersionTag.parse(current_tag)
    prior_version_tag = Dor::VersionTag.parse(previous_tag)
    return :major if cur_version_tag.major != prior_version_tag.major
    return :minor if cur_version_tag.minor != prior_version_tag.minor
    return :admin if cur_version_tag.admin != prior_version_tag.admin

    nil
  end

  def load_and_authorize_resource
    @cocina_object = Dor::Services::Client.object(params[:item_id]).find
    authorize! :manage_item, @cocina_object
  end
end
