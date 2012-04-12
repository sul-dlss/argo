class AboutController < ApplicationController

  def index
    sections = { 
      'Ruby' => /^(RUBY|GEM_|rvm)/,
      'HTTP Server' => /^(SERVER_|POW_)/,
#      'HTTP Request' => /^(HTTP|PATH|QUERY|REQUEST|SCRIPT)_/,
      'WebAuth' => /^WEBAUTH_/
    }
    @request_env = Hash.new { |h,k| h[k] = {} }
    [ENV,request.env].each do |environment|
      environment.each_pair do |key,value|
        section = sections.keys.find { |k| key =~ sections[k] }
        unless section.nil?
          @request_env[section][key] = value if value.is_a? String
        end
      end
    end
    
    @solr = Dor::SearchService.solr.luke(:show => 'schema', :numTerms => 0)['index']
    @fedora = ActiveFedora::Base.connection_for_pid(0).profile
  end
  
end
