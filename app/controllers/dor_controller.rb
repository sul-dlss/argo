class DorController < ApplicationController
  before_action :authorize!
  respond_to :json, :xml
  respond_to :text, :only => [:query_by_id, :reindex, :delete_from_index]

  def query_by_id
    unless params[:id]
      response.status = 400
      return
    end

    result = Dor::SearchService.query_by_id(params[:id]).collect do |pid|
      { :id => pid, :url => url_for(:controller => 'dor/objects', :id => pid) }
    end

    respond_with(result) do |format|
      format.any(:json, :xml) { render request.format.to_sym => result }
      format.text { render :text => result.collect { |v| v[:id] }.join("\n") }
    end
  end

  def label
    respond_with params.merge('label' => Dor::MetadataService.label_for(params[:source_id]))
  end

  def reindex
    @solr_doc = Argo::Indexer.reindex_pid params[:pid], Argo::Indexer.generate_index_logger { request.uuid }
    Dor::SearchService.solr.commit # reindex_pid doesn't commit, but callers of this method may expect the update to be committed immediately
    flash[:notice] = "Successfully updated index for #{params[:pid]}"
    unless request.headers['Referer']
      render status: 200, text: flash[:notice]
      return
    end
    redirect_back(
      fallback_location: proc { catalog_path(params[:pid])}
    )
  rescue ActiveFedora::ObjectNotFoundError
    flash[:error] = 'Object does not exist in Fedora.'
    unless request.headers['Referer']
      render status: 404, text: flash[:error]
      return
    end
    redirect_back(
      fallback_location: proc { catalog_path(params[:pid])}
    )
  end

  def delete_from_index
    Dor::SearchService.solr.delete_by_id(params[:pid])
    Dor::SearchService.solr.commit
    render :text => params[:pid]
  end

  def republish
    obj = Dor::Item.find(params[:pid])
    obj.publish_metadata_remotely
    redirect_to catalog_path(params[:pid]), notice: 'Republished! You still need to use the normal versioning process to make sure your changes are preserved.'
  end
end
