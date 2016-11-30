class DorController < ApplicationController
  # dispatches the reindexing request to the remote reindexing service
  def reindex
    begin
      Dor::IndexingService.reindex_pid_remotely params[:pid]
      flash[:notice] = "Successfully updated index for #{params[:pid]}"
    rescue Dor::IndexingService::ReindexError => e
      flash[:error] = "Failed to update index for #{params[:pid]}"
      Rails.logger.error "#{flash[:error]}: #{e.inspect}"
    end

    # it needs to support both bulk actions and the blue button
    if params[:bulk] == 'true'
      if flash[:notice]
        render status: 200, plain: flash[:notice]
      else
        render status: 500, plain: flash[:error]
      end
    else
      redirect_back(
        fallback_location: proc { solr_document_path(params[:pid])}
      )
    end
  end

  # dispatches to the dor-services-app to republish
  def republish
    obj = Dor.find(params[:pid])
    obj.publish_metadata_remotely
    redirect_to solr_document_path(params[:pid]), notice: 'Republished! You still need to use the normal versioning process to make sure your changes are preserved.'
  end
end
