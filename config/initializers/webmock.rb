def mock_workflow_requests
  escaped_url = Settings.WORKFLOW_URL.gsub('/', '\/')
  stub_request(:get, /#{escaped_url}workflow_archive.*/).
    to_return(body: '<objects count="1"/>')
  stub_request(:get, /#{escaped_url}dor.*/).
    to_return(body: '<workflows/>')
end

unless Rails.env.production?
  require 'webmock'
  include WebMock::API
  WebMock.allow_net_connect!
  mock_workflow_requests unless Settings.DISABLE_WEBMOCK
end
