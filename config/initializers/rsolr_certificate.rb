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

Rails.logger.warn "Monkey-patching RSolr::ClientCert::Connection to use POST for any attempted GET requests"
class RSolr::ClientCert::Connection
  def execute client, request_context
    old_proxy = RestClient.proxy
    begin
      RestClient.proxy = request_context[:proxy]
      resource = RestClient::Resource.new(
      request_context[:uri].to_s,
      :open_timeout     =>  request_context[:open_timeout],
      :timeout          =>  request_context[:read_timeout],
      :ssl_client_cert  =>  ssl_client_cert,
      :ssl_client_key   =>  ssl_client_key
      )
      result = {}
      if request_context[:method] == :get
        response=resource.post request_context[:data], {}
        result = {
          :status => response.net_http_res.code.to_i,
          :headers => response.net_http_res.to_hash,
          :body => response.net_http_res.body
        }
      else 
        signature = [request_context[:method], request_context[:data], request_context[:headers]].compact
        resource.send(*signature) { |response, request, http_result, &block|
          result = {
            :status => response.net_http_res.code.to_i,
            :headers => response.net_http_res.to_hash,
            :body => response.net_http_res.body
          }
        }
      end
      result
    ensure
      RestClient.proxy = old_proxy
    end
  end
end