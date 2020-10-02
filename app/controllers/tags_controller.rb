# frozen_string_literal: true

# This controller is responsible for managing tags on an item
class TagsController < ApplicationController
  def search
    render json: Dor::Services::Client.administrative_tags.search(q: params[:q])
  rescue Dor::Services::Client::ConnectionFailed
    render json: []
    raise
  end

  def update
    cocina = Dor::Services::Client.object(params[:item_id]).find
    authorize! :manage_item, cocina

    current_tags = tags_client.list

    if params[:add]
      tags = params.slice(:new_tag1, :new_tag2, :new_tag3).values.reject(&:empty?)
      tags_client.create(tags: tags) if tags.any?
    end

    if params[:del]
      tag_to_delete = current_tags[params[:tag].to_i - 1]
      raise 'failed to delete' unless tags_client.destroy(tag: tag_to_delete)
    end

    if params[:update]
      count = 1
      current_tags.each do |tag|
        tags_client.update(current: tag, new: params["tag#{count}".to_sym])
        count += 1
      end
    end

    reindex
    respond_to do |format|
      msg = "Tags for #{params[:item_id]} have been updated!"
      format.any { redirect_to solr_document_path(params[:item_id]), notice: msg }
    end
  end

  def edit
    @pid = params[:item_id]
    @tags = tags_client.list

    respond_to do |format|
      format.html { render layout: !request.xhr? }
    end
  end

  private

  def tags_client
    Dor::Services::Client.object(params[:item_id]).administrative_tags
  end

  def reindex
    Argo::Indexer.reindex_pid_remotely(params[:item_id])
  end
end
