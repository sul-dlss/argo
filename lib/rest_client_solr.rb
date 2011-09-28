require 'rest-client'

module RSolr

class DorConnection

  def execute client, request_context
    resource = RestClient::Resource.new(
      request_context[:uri].to_s,
      :ssl_client_cert  =>  OpenSSL::X509::Certificate.new(File.read(Dor::Config.fedora.cert_file)),
      :ssl_client_key   =>  OpenSSL::PKey::RSA.new(File.read(Dor::Config.fedora.key_file), Dor::Config.fedora.key_pass)
    )
    result = {}
    resource.send(request_context[:method]) { |response, request, result, &block|
      result = {
        :status => response.net_http_res.code.to_i,
        :headers => response.net_http_res.to_hash,
        :body => response.net_http_res.body
      }
    }
    result
  end
  
end

end
