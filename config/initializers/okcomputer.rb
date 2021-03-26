# frozen_string_literal: true

require 'okcomputer'

# /status for 'upness', e.g. for load balancer
# /status/all to show all dependencies
# /status/<name-of-check> for a specific check (e.g. for nagios warning)
OkComputer.mount_at = 'status'
OkComputer.check_in_parallel = true

# check models to see if at least they have some data
class TablesHaveDataCheck < OkComputer::Check
  def check
    msg = [
      BulkAction,
      User
    ].map { |klass| table_check(klass) }.join(' ')
    mark_message msg
  end

  private

  # @return [String] message
  def table_check(klass)
    # has at least 1 record
    return "#{klass.name} has data." if klass.any?

    mark_failure
    "#{klass.name} has no data."
  rescue => e # rubocop:disable Style/RescueStandardError
    mark_failure
    "#{e.class.name} received: #{e.message}."
  end
end

# REQUIRED checks, required to pass for /status/all
#  individual checks also avail at /status/<name-of-check>
OkComputer::Registry.register 'ruby_version', OkComputer::RubyVersionCheck.new
OkComputer::Registry.register 'rails_cache', OkComputer::GenericCacheCheck.new
OkComputer::Registry.register 'feature-tables-have-data', TablesHaveDataCheck.new

solr_url = Blacklight.connection_config.fetch(:url)
OkComputer::Registry.register 'dor_search_service_solr', OkComputer::HttpCheck.new("#{solr_url}/admin/ping")

# ------------------------------------------------------------------------------

# NON-CRUCIAL (Optional) checks, avail at /status/<name-of-check>
#   - at individual endpoint, HTTP response code reflects the actual result
#   - in /status/all, these checks will display their result text, but will not affect HTTP response code
OkComputer::Registry.register 'dor_services_url', OkComputer::HttpCheck.new(Settings.dor_services.url)
OkComputer::Registry.register 'workflow_url', OkComputer::HttpCheck.new(Settings.workflow_url)

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

OkComputer.make_optional %w[
  bulk_metadata_dir
  bulk_metadata_tmp_dir
  dor_services_url
  modsulator_url
  normalizer_url
  spreadsheet_url
  stacks_file_url
  stacks_host
  stacks_local_workspace_root
  stacks_thumbnail_url
  workflow_url
]
