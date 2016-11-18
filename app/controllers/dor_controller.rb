class DorController < ApplicationController
  respond_to :json, :xml
  respond_to :text, :only => [:reindex, :delete_from_index]

  def reindex
    @solr_doc = Argo::Indexer.reindex_pid params[:pid], Argo::Indexer.generate_index_logger { request.uuid }
    Dor::SearchService.solr.commit # reindex_pid doesn't commit, but callers of this method may expect the update to be committed immediately
    flash[:notice] = "Successfully updated index for #{params[:pid]}"
    unless request.headers['Referer']
      render status: 200, plain: flash[:notice]
      return
    end
    redirect_back(
      fallback_location: proc { catalog_path(params[:pid])}
    )
  rescue ActiveFedora::ObjectNotFoundError
    flash[:error] = 'Object does not exist in Fedora.'
    unless request.headers['Referer']
      render status: 404, plain: flash[:error]
      return
    end
    redirect_back(
      fallback_location: proc { catalog_path(params[:pid])}
    )
  end

  def delete_from_index
    Dor::SearchService.solr.delete_by_id(params[:pid])
    Dor::SearchService.solr.commit
    render :plain => params[:pid]
  end

  def republish
    obj = Dor.find(params[:pid])
    obj.publish_metadata_remotely
    redirect_to catalog_path(params[:pid]), notice: 'Republished! You still need to use the normal versioning process to make sure your changes are preserved.'
  end
end
