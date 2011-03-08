require 'active_support'
require 'dor-services'
require 'rack/conneg'
require 'sinatra'

class DorServicesApp < Sinatra::Base
  
  use(Rack::Conneg) do |conneg|
    conneg.set :accept_all_extensions, false
    conneg.set :fallback, :xml
    conneg.provide([:json, :xml, :text])
  end

  configure do
    set(:running_in) { |regex| condition { regex.match(settings.environment.to_s).nil? == false } }
    require File.join(File.dirname(__FILE__),"../config/environments/#{settings.environment}.rb")
    fedora_base = URI.parse(Dor::Config[:fedora_url])
    fedora_base.user = fedora_base.password = nil
    set(:fedora_base,fedora_base)
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
    content_type :json
    Dor::Config.to_hash.merge({:environment, options.environment}).to_json
  end

  post '/objects' do
    dor_params = {
      :admin_policy  => params[:admin_policy],
      :content_model => params[:model],
      :label         => params[:label],
      :object_type   => params[:object_type],
      :other_ids     => ids_to_hash(params[:other_id]),
      :parent        => params[:parent],
      :source_id     => ids_to_hash(params[:source_id]),
      :tags          => params[:tag]
    }
  
    begin
      dor_response = Dor::RegistrationService.register_object(dor_params)
      content_type :text
      status dor_response[:response].code
      headers "Location" => settings.fedora_base.merge("objects/#{dor_response[:pid]}").to_s
      body dor_response[:pid]
    rescue Dor::ParameterError => e
      halt 400, e.message
    rescue Dor::DuplicateIdError => e
      halt 409, e.message
    end
  end

  get '/query_by_id' do
    halt 400 unless params[:id]
    result = Dor::RegistrationService.query_by_id(params[:id]).collect do |pid|
      { :id => pid, :url => url("/objects/#{pid}") }
    end

    content_type negotiated_type
    respond_to do |wants|
      wants.text { result.collect { |v| v[:id] }.join("\n") }
      wants.xml  { nokogiri :query_by_id, :locals => { :data => result } }
      wants.json { result.to_json }
    end
  end

end