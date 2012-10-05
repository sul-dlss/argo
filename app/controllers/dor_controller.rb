class DorController < ApplicationController
  around_filter :development_only!, :only => :configuration
  before_filter :authorize!
  respond_to :json, :xml
  respond_to :text, :only => [:query_by_id, :reindex, :delete_from_index]
  
  def configuration
    result = Dor::Config.to_hash.merge({
      :environment => Rails.env, 
      :webauth => { 
        :authrule => webauth.authrule,
        :logged_in => webauth.logged_in?,
        :login => webauth.login,
        :attributes => webauth.attributes,
        :privgroup => webauth.privgroup
      }
    })
    respond_with(result)
  end
  
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
    obj = Dor.load_instance params[:pid]
    solr_doc = obj.to_solr
    Dor::SearchService.solr.add(solr_doc, :add_attributes => {:commitWithin => 1000}) unless obj.nil?

    render :text => solr_doc
  end

  def delete_from_index
    Dor::SearchService.solr.delete_by_id(params[:pid])
    Dor::SearchService.solr.commit
    render :text => params[:pid]
  end
end
