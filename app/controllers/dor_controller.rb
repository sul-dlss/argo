# frozen_string_literal: true

class DorController < ApplicationController
  # dispatches the reindexing request to the remote reindexing service
  def reindex
    begin
      Argo::Indexer.reindex_druid_remotely params[:druid]
      flash.now[:notice] = "Successfully updated index for #{params[:druid]}"
    rescue Argo::Exceptions::ReindexError => e
      flash.now[:error] = "Failed to update index for #{params[:druid]}"
      Rails.logger.error "#{flash[:error]}: #{e.inspect}"
    end

    redirect_back(
      fallback_location: proc { solr_document_path(params[:druid]) }
    )
  end
end
