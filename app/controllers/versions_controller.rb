# frozen_string_literal: true

class VersionsController < ApplicationController
  before_action :create_obj

  def open_ui
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def close_ui
    @description = @object.datastreams['versionMetadata'].current_description
    @tag = @object.datastreams['versionMetadata'].current_tag

    # do some stuff to figure out which part of the version number changed when opening
    # the item for versioning, so that the form can pre-select the correct significance level
    @changed_significance = which_significance_changed(get_current_version_tag(@object), get_prior_version_tag(@object))
    @significance_selected = {}
    %i[major minor admin].each do |significance|
      @significance_selected[significance] = (@changed_significance == significance)
    end

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  def open
    authorize! :manage_item, @object

    VersionService.open(identifier: @object.pid,
                        significance: params[:significance],
                        description: params[:description],
                        opening_user_name: current_user.to_s)
    msg = "#{@object.pid} is open for modification!"
    redirect_to solr_document_path(params[:item_id]), notice: msg
    reindex
  rescue StandardError => e
    raise e unless e.to_s == 'Object net yet accessioned'

    render status: :internal_server_error, plain: 'Object net yet accessioned'
    nil
  end

  # as long as this isn't a bulk operation, and we get non-nil significance and description
  # values, update those fields on the version metadata datastream
  def close
    authorize! :manage_item, @object

    begin
      VersionService.close(
        identifier: @object.pid,
        description: params[:description],
        significance: params[:significance],
        user_name: current_user.to_s
      )
      msg = "Version #{@object.current_version} of #{@object.pid} has been closed!"
      redirect_to solr_document_path(params[:item_id]), notice: msg
      reindex
    rescue Dor::Exception # => e
      render status: :internal_server_error, plain: 'No version to close.'
    end
  end

  private

  # create an instance of VersionTag for the current version of item
  # @return [String] current tag
  def get_current_version_tag(item)
    ds = item.datastreams['versionMetadata']
    Dor::VersionTag.parse(ds.tag_for_version(ds.current_version_id))
  end

  # create an instance of VersionTag for the second most recent version of item
  # @return [String] prior tag
  def get_prior_version_tag(item)
    ds = item.datastreams['versionMetadata']
    prior_version_id = (Integer(ds.current_version_id) - 1).to_s
    Dor::VersionTag.parse(ds.tag_for_version(prior_version_id))
  end

  # Given two instances of VersionTag, find the most significant difference
  # between the two (return nil if either one is nil or if they're the same)
  # @param [String] cur_version_tag   current version tag
  # @param [String] prior_version_tag prior version tag
  # @return [Symbol] :major, :minor, :admin or nil
  def which_significance_changed(cur_version_tag, prior_version_tag)
    return nil if cur_version_tag.nil? || prior_version_tag.nil?
    return :major if cur_version_tag.major != prior_version_tag.major
    return :minor if cur_version_tag.minor != prior_version_tag.minor
    return :admin if cur_version_tag.admin != prior_version_tag.admin

    nil
  end

  # Filters
  def create_obj
    @object = Dor.find params[:item_id]
  end

  def reindex
    Argo::Indexer.reindex_pid_remotely(@object.pid)
  end
end
