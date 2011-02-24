require 'sinatra'
require 'dor-services'
require 'json'

class DorService < Sinatra::Base

  configure do
    require File.join(File.dirname(__FILE__),"../config/environments/#{environment}.rb")
  end

  get '/config' do
    development? || (halt 404)
    content_type 'application/json'
    Dor::Config.to_hash.to_json
  end

end