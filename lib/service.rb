require 'sinatra'
require 'dor-services'
require 'active_support'

configure do
  set(:running_in) { |regex| condition { regex.match(settings.environment.to_s).nil? == false } }
  require File.join(File.dirname(__FILE__),"../config/environments/#{settings.environment}.rb")
end

before do
  case request.content_type
  when 'application/xml','text/xml'
    merge_params(Hash.from_xml(request.body.read))
  when 'application/json','text/json'
    merge_params(JSON.parse(request.body.read))
  end
end

helpers do
  def merge_params(hash)
    # convert camelCase parameter names to under_score, and string keys to symbols
    # e.g., 'objectType' to :object_type
    hash.each_pair { |k,v| 
      key = k.underscore
      params[key.to_sym] = v
    }
  end
  
  def ids_to_hash(ids)
    if ids.nil?
      nil
    else
      Hash[Array(ids).collect { |id| id.split(/:/) }]
    end
  end
end

get '/config', :running_in => /development/ do
  content_type 'application/json'
  Dor::Config.to_hash.merge({:environment, options.environment}).to_json
end

post '/objects' do
  unless params[:source_id].nil?
    source_info = params[:source_id].to_s.split(/:/)
    params[:source_id] = { :source => source_info[0], :value => source_info[1] }
  end
  
  dor_params = {
    :admin_policy  => params[:admin_policy],
    :content_model => params[:model],
    :label         => params[:label],
    :object_type   => params[:object_type],
    :other_ids     => ids_to_hash(params[:other_id]),
    :parent        => params[:parent],
    :source_id     => params[:source_id],
    :tags          => params[:tag]
  }
  
  begin
    dor_response = Dor::RegistrationService.register_object(dor_params)
    response.status = dor_response[:response].code
    dor_response[:pid]
  rescue Dor::DuplicateIdError => e
    halt 409, e.message
  end
end
