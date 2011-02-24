cert_dir = File.expand_path(File.join(File.dirname(__FILE__),"../certs"))

Dor::Config.configure do |config|
  config.fedora_url = 'http://fedoraAdmin:fedoraAdmin@dor-dev.stanford.edu/fedora'
  config.fedora_cert_file = File.join(cert_dir,"dlss-dev-test.crt")
  config.fedora_key_file = File.join(cert_dir,"dlss-dev-test.key")
#    config.fedora_key_pass = nil

  config.gsearch_solr_url = 'http://dor-dev.stanford.edu/solr'
  config.mint_suri_ids = true
  config.id_namespace = 'druid'
  config.suri_url = 'http://lyberservices-dev.stanford.edu:8080'
  config.suri_user = 'hydra-etd'
  config.suri_password = 'lyberteam'
end
