require 'rsolr/client_cert'

# Force Blacklight to use RSolr::ClientCert::Connection
Rails.logger.warn "Monkey-patching Blacklight.solr to use RSolr::ClientCert::Connection"
begin
  Blacklight.instance_variable_set(:@solr, Dor::Config.make_solr_connection(Blacklight.solr_config))
end

# Monkey patch Solrizer::Fedora::Indexer to use RSolr::ClientCert::Connection
Rails.logger.warn "Monkey-patching Solrizer::Fedora::Indexer to use RSolr::ClientCert::Connection"
class Solrizer::Fedora::Indexer
  def connect
    @solr = Dor::Config.make_solr_connection
  end
end