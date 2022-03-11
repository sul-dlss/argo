# frozen_string_literal: true

class DorController < ApplicationController
  # dispatches the reindexing request to the remote reindexing service
  def reindex
    begin
      Argo::Indexer.reindex_pid_remotely params[:pid]
      flash[:notice] = "Successfully updated index for #{params[:pid]}"
    rescue Argo::Exceptions::ReindexError => e
      flash[:error] = "Failed to update index for #{params[:pid]}"
      Rails.logger.error "#{flash[:error]}: #{e.inspect}"
    end

    redirect_back(
      fallback_location: proc { solr_document_path(params[:pid]) }
    )
  end
end
