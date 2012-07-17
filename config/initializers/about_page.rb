AboutPage.configure do |config|
  config.app = { :name => 'Argo', :version => Argo.version }

  config.dependencies = AboutPage::Dependencies.new

  config.environment = AboutPage::Environment.new({ 
    'Ruby' => /^(RUBY|GEM_|rvm)/
  })

  config.request = AboutPage::RequestEnvironment.new({
    'HTTP Server' => /^(SERVER_|POW_)/,
    'WebAuth' => /^WEBAUTH_/
  })

  config.fedora = AboutPage::Fedora.new(ActiveFedora::Base.connection_for_pid(0))
  config.solr = AboutPage::Solr.new(Dor::SearchService.solr, :expects => { :numDocs => 0 })
end
