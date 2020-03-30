# frozen_string_literal: true

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
# fedora_url is covered by checking ActiveFedora::Base.connection_for_pid(0)

# remove trailing slashes to avoid constructing bad solr ping URLs
OkComputer::Registry.register 'dor_search_service_solr', OkComputer::HttpCheck.new(ActiveFedora.solr.conn.uri.to_s.sub(%r{/$}, '') + '/admin/ping')
# solrizer_url is coverd by checking ActiveFedora.solr.conn.uri

# ------------------------------------------------------------------------------

# NON-CRUCIAL (Optional) checks, avail at /status/<name-of-check>
#   - at individual endpoint, HTTP response code reflects the actual result
#   - in /status/all, these checks will display their result text, but will not affect HTTP response code
OkComputer::Registry.register 'dor_services_url', OkComputer::HttpCheck.new(Settings.dor_services.url)
OkComputer::Registry.register 'robot_status_url', OkComputer::HttpCheck.new(Settings.robot_status_url)
OkComputer::Registry.register 'workflow_url', OkComputer::HttpCheck.new(Settings.workflow_url)

# suri is essential for registering objects
OkComputer::Registry.register 'suri_url', OkComputer::HttpCheck.new(Settings.suri.url)

# Stacks
OkComputer::Registry.register 'stacks_local_workspace_root', OkComputer::DirectoryCheck.new(Settings.stacks.local_workspace_root)
OkComputer::Registry.register 'stacks_host', OkComputer::HttpCheck.new("https://#{Settings.stacks.host}")
OkComputer::Registry.register 'stacks_file_url', OkComputer::HttpCheck.new(Settings.stacks_file_url)
OkComputer::Registry.register 'stacks_thumbnail_url', OkComputer::HttpCheck.new(Settings.stacks_url)

# Bulk Metadata - probably for bulk downloads
OkComputer::Registry.register 'bulk_metadata_dir', OkComputer::DirectoryCheck.new(Settings.bulk_metadata.directory)
OkComputer::Registry.register 'bulk_metadata_tmp_dir', OkComputer::DirectoryCheck.new(Settings.bulk_metadata.temporary_directory)

# Modsulator, etc - probably for bulk updates?
OkComputer::Registry.register 'modsulator_url', OkComputer::HttpCheck.new(Settings.modsulator_url)
OkComputer::Registry.register 'normalizer_url', OkComputer::HttpCheck.new(Settings.normalizer_url)
OkComputer::Registry.register 'spreadsheet_url', OkComputer::HttpCheck.new(Settings.spreadsheet_url)

# purl_url is only used for links out and we decided not to include it here

OkComputer.make_optional %w(
  bulk_metadata_dir
  bulk_metadata_tmp_dir
  dor_services_url
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
