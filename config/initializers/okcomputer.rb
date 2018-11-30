require 'okcomputer'

# /status for 'upness', e.g. for load balancer
# /status/all to show all dependencies
# /status/<name-of-check> for a specific check (e.g. for nagios warning)
OkComputer.mount_at = 'status'
OkComputer.check_in_parallel = true

class RubydoraCheck < OkComputer::PingCheck
  def initialize(options = {})
    @client = options[:client]
    raise ArgumentError.new(':client not specified') unless @client

    self.host = options[:host] || URI(@client.client.url).host
    self.port = options[:port] || URI(@client.client.url).port
    self.request_timeout = options[:timeout].to_i || 5
  end

  def check
    tcp_socket_request
    message_lines = ['Rubydora check successful<br/>', '<ul>']
    %w(repositoryName repositoryBaseURL repositoryVersion).each do |key|
      message_lines << "<li>#{key} - #{profile[key]}\</li>"
    end
    message_lines << '</ul>'
    mark_message message_lines.join('')
  rescue => e
    mark_message "Error: '#{e}'"
    mark_failure
  end

  def profile
    @luke ||= begin
                @client.profile
              rescue
                {}
              end
  end
end

# REQUIRED checks, required to pass for /status/all
#  individual checks also avail at /status/<name-of-check>
OkComputer::Registry.register 'ruby_version', OkComputer::RubyVersionCheck.new
OkComputer::Registry.register 'rails_cache', OkComputer::GenericCacheCheck.new

OkComputer::Registry.register 'active_fedora_conn', RubydoraCheck.new(client: ActiveFedora::Base.connection_for_pid(0))
# FEDORA_URL is covered by checking ActiveFedora::Base.connection_for_pid(0)

# remove trailing slashes to avoid constructing bad solr ping URLs
OkComputer::Registry.register 'dor_search_service_solr', OkComputer::HttpCheck.new(Dor::SearchService.solr.uri.to_s.sub(%r{/$}, '') + '/admin/ping')
# SOLRIZER_URL is coverd by checking Dor::SearchService.solr.uri

# ------------------------------------------------------------------------------

# NON-CRUCIAL (Optional) checks, avail at /status/<name-of-check>
#   - at individual endpoint, HTTP response code reflects the actual result
#   - in /status/all, these checks will display their result text, but will not affect HTTP response code
OkComputer::Registry.register 'dor_services_url', OkComputer::HttpCheck.new(Settings.DOR_SERVICES_URL)
OkComputer::Registry.register 'robot_status_url', OkComputer::HttpCheck.new(Settings.ROBOT_STATUS_URL)
OkComputer::Registry.register 'workflow_url', OkComputer::HttpCheck.new(Settings.WORKFLOW_URL)

# suri is essential for registering objects
OkComputer::Registry.register 'suri_url', OkComputer::HttpCheck.new(Settings.SURI.URL)

# Stacks
OkComputer::Registry.register 'stacks_local_workspace_root', OkComputer::DirectoryCheck.new(Settings.STACKS.LOCAL_WORKSPACE_ROOT)
OkComputer::Registry.register 'stacks_host', OkComputer::HttpCheck.new("https://#{Settings.STACKS.HOST}")
OkComputer::Registry.register 'stacks_file_url', OkComputer::HttpCheck.new(Settings.STACKS_FILE_URL)
OkComputer::Registry.register 'stacks_thumbnail_url', OkComputer::HttpCheck.new(Settings.STACKS_URL)

# Content
OkComputer::Registry.register 'content_base_dir', OkComputer::DirectoryCheck.new(Settings.CONTENT.BASE_DIR)
OkComputer::Registry.register 'content_server_host', OkComputer::HttpCheck.new("https://#{Settings.CONTENT.SERVER_HOST}")

# the catalog service needs an explicit catkey.
OkComputer::Registry.register 'metadata_catalog_url', OkComputer::HttpCheck.new(Settings.METADATA.CATALOG_URL + '?catkey=1')

# Bulk Metadata - probably for bulk downloads
OkComputer::Registry.register 'bulk_metadata_dir', OkComputer::DirectoryCheck.new(Settings.BULK_METADATA.DIRECTORY)
OkComputer::Registry.register 'bulk_metadata_tmp_dir', OkComputer::DirectoryCheck.new(Settings.BULK_METADATA.TEMPORARY_DIRECTORY)

# Modsulator, etc - probably for bulk updates?
OkComputer::Registry.register 'modsulator_url', OkComputer::HttpCheck.new(Settings.MODSULATOR_URL)
OkComputer::Registry.register 'normalizer_url', OkComputer::HttpCheck.new(Settings.NORMALIZER_URL)
OkComputer::Registry.register 'spreadsheet_url', OkComputer::HttpCheck.new(Settings.SPREADSHEET_URL)

# PURL_URL is only used for links out and we decided not to include it here

OkComputer.make_optional %w(
  bulk_metadata_dir
  bulk_metadata_tmp_dir
  content_base_dir
  content_server_host
  dor_services_url
  metadata_catalog_url
  modsulator_url
  normalizer_url
  robot_status_url
  spreadsheet_url
  stacks_file_url
  stacks_host
  stacks_local_workspace_root
  stacks_thumbnail_url
  suri_url
  workflow_url
)
