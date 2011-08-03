class ItemsController < ApplicationController
  before_filter :authorize!
  
  def crop
    @druid = params[:id].sub(/^druid:/,'')
    files = Legacy::Object.find_by_druid(@druid).files.find_all_by_file_role('00').sort { |a,b| a.id <=> b.id }
    @image_data = files.collect do |file|
      hash = file.webcrop
      hash[:fileSrc] = "#{ENV['RACK_BASE_URI']}/images/.dpg_pool/#{hash[:fileSrc]}"
      hash
    end
    render :crop, :layout => 'webcrop'
  end
  
  def save_crop
    @druid = params[:id].sub(/^druid:/,'')
    @image_data = JSON.parse(request.body.read)
    @image_data.each { |file_data|
      file_data.symbolize_keys!
      file_data[:cropCoords].symbolize_keys! if file_data.has_key?(:cropCoords)
      file = Legacy::File.find(file_data[:id])
      file.webcrop = file_data
    }
    render :json => @image_data.to_json
  end
  
  def register
    @perm_keys = ["sunetid:#{webauth.login}"] 
    unless webauth.privgroup.nil?
      @perm_keys += webauth.privgroup.split(/\|/).collect { |g| "workgroup:#{g}" }
    end
    render :register
  end

  def reindex
    @druids = Array(params[:id])
    result = @druids.inject({}) { |hash,druid| hash[druid] = Dor::Base.load_instance(druid).reindex; hash }
    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => result }
    end
  end
  
end
