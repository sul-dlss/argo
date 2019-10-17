# frozen_string_literal: true

class ContentTypesController < ApplicationController
  before_action :load_resource

  def show
    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  # set the content type in the content metadata
  def update
    authorize! :manage_item, @object

    # if this object has been submitted and doesnt have an open version, they cannot change it.
    state_service = StateService.new(@object.pid, version: @object.current_version)
    return render_error('Object cannot be modified in its current state.') unless state_service.allows_modification?
    return render_error('Invalid new content type.') unless valid_content_type?
    return render_error('Object doesnt have a content metadata datastream to update.') unless has_content?

    @object.contentMetadata.set_content_type(
      params[:old_content_type],
      params[:old_resource_type],
      params[:new_content_type],
      params[:new_resource_type]
    )

    respond_to do |format|
      if params[:bulk]
        format.html { render plain: 'Content type updated.' }
      else
        format.any { redirect_to solr_document_path(params[:item_id]), notice: 'Content type updated!' }
      end
    end
    @object.save
    ActiveFedora.solr.conn.add(@object.to_solr) unless params[:bulk]
  end

  private

  def render_error(msg)
    render status: :forbidden, plain: msg
  end

  def valid_content_type?
    Constants::CONTENT_TYPES.include? params[:new_content_type]
  end

  # rubocop:disable Naming/PredicateName
  def has_content?
    @object.datastreams.include? 'contentMetadata'
  end
  # rubocop:enable Naming/PredicateName

  # Filters
  def load_resource
    obj_pid = params[:item_id]
    raise 'missing druid' unless obj_pid

    @object = Dor.find(obj_pid)
  end
end
