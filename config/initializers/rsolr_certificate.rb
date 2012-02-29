require 'rsolr/client_cert'

# Force Blacklight to use RSolr::ClientCert::Connection
Rails.logger.warn "Monkey-patching Blacklight.solr to use RSolr::ClientCert::Connection"
begin
  opts = Blacklight.solr_config.merge(:ssl_cert_file => Dor::Config.fedora.cert_file, :ssl_key_file => Dor::Config.fedora.key_file, :ssl_key_pass => Dor::Config.fedora.key_pass)
  conn = RSolr::ClientCert.connect opts
  Blacklight.instance_variable_set(:@solr, conn)
end

# Monkey patch Solrizer::Fedora::Indexer to use RSolr::ClientCert::Connection
Rails.logger.warn "Monkey-patching Solrizer::Fedora::Indexer to use RSolr::ClientCert::Connection"
class Solrizer::Fedora::Indexer
  def connect
    opts = Dor::Config.solrizer.opts.merge(
      :url => Dor::Config.solrizer.url,
      :ssl_cert_file => Dor::Config.fedora.cert_file, :ssl_key_file => Dor::Config.fedora.key_file, :ssl_key_pass => Dor::Config.fedora.key_pass
    )
    @solr = RSolr::ClientCert.connect opts
  end
end