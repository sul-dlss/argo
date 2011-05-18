cert_dir = File.expand_path(File.join(File.dirname(__FILE__),"../certs"))

Dor::Config.configure do
  fedora do
    url 'http://fedoraAdmin:fedoraAdmin@dor-dev.stanford.edu/fedora'
    cert_file File.join(cert_dir,"dlss-dev-test.crt")
    key_file File.join(cert_dir,"dlss-dev-test.key")
    key_pass ''
  end
  
  gsearch.url 'http://dor-dev.stanford.edu/solr'
  
  suri do
    mint_ids true
    id_namespace 'druid'
    url 'http://lyberservices-dev.stanford.edu:8080'
    user 'labware'
    pass 'lyberteam'
  end

  metadata do
    exist.url 'http://viewer:l3l%40nd@lyberapps-dev.stanford.edu/exist/rest'
    catalog.url 'http://lyberservices-prod.stanford.edu/catalog/mods'
  end
end
