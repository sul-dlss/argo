##
# We need to include webmock in both the development and
# test environments because `argo:repo:load` will try to
# contact the workflow service during Solrization.
#
# Note that requiring webmock breaks Net::HTTP::Persistent so
# it should NOT be bundled in a production (or stage) deployment.
#
if !Settings.DISABLE_WEBMOCK && (Rails.env.development? || Rails.env.test?)
  require 'webmock'
  include WebMock::API
  WebMock.allow_net_connect!

  # mock_workflow_requests
  escaped_url = Settings.WORKFLOW_URL.gsub('/', '\/')
  stub_request(:get, /#{escaped_url}workflow_archive.*/).
    to_return(body: '<objects count="1"/>')
  stub_request(:get, /#{escaped_url}dor.*/).
    to_return(body: '<workflows/>')

  # mock_status_requests
  stub_request(:get, Settings.STATUS_INDEXER_URL).to_return(status: 404)
end
