class DorController < ApplicationController
  respond_to :json, :xml
  respond_to :text, :only => :query_by_id

  def configuration
    if Rails.env.development?
      result = Dor::Config.to_hash.merge({
        :environment => Rails.env, 
        :webauth => { 
          :authrule => webauth.authrule,
          :logged_in => webauth.logged_in?,
          :login => webauth.login,
          :attributes => webauth.attributes
        }
      })
      respond_with(result)
    else
      render :text => 'Not Found', :status => :not_found
    end
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
  
end
