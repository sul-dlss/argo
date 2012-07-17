require 'uri'
require 'nokogiri'
require 'is_it_working'
Rails.configuration.middleware.use(IsItWorking::Handler) do |h|
  # Check that AwesomeService is working using the service's own logic
  h.check :rubydora, :client => ActiveFedora::Base.connection_for_pid(0)
  h.check :rsolr, :client => Dor::SearchService.solr
end
