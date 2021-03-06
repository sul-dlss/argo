# frozen_string_literal: true

class DorController < ApplicationController
  # dispatches the reindexing request to the remote reindexing service
  def reindex
    if params[:bulk]
      render status: :forbidden, plain: 'the old bulk update mechanism is deprecated.  please use the new bulk actions framework going forward.'
      return
    end

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

  # dispatches to the dor-services-app to republish
  def republish
    Dor::Services::Client.object(params[:pid]).publish
    redirect_to solr_document_path(params[:pid]),
                notice: 'Republished! You still need to use the normal versioning ' \
                        'process to make sure your changes are preserved.'
  end
end
