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
  rescue StandardError => e
    mark_failure
    "#{e.class.name} received: #{e.message}."
  end
end

class OcrQueueDepthCheck < OkComputer::Check
  MAX_OCR_WAITING = 20 # alert if we have more than this number of objects waiting in ocrWF:ocr-create

  def check
    num_ocr_waiting = SearchService.query('wf_wps_ssim:ocrWF:ocr-create:waiting', fl: 'id')['response']['numFound']

    msg = "ocrWF:ocr-create step has #{num_ocr_waiting} waiting"
    if num_ocr_waiting > MAX_OCR_WAITING
      mark_failure
      msg += " (more than #{MAX_OCR_WAITING})"
    end

    mark_message msg
  end
end

# REQUIRED checks, required to pass for /status/all
#  individual checks also avail at /status/<name-of-check>
OkComputer::Registry.register 'ruby_version', OkComputer::RubyVersionCheck.new
OkComputer::Registry.register 'rails_cache', OkComputer::GenericCacheCheck.new
OkComputer::Registry.register 'feature-tables-have-data', TablesHaveDataCheck.new

solr_url = Blacklight.connection_config.fetch(:url)
OkComputer::Registry.register 'dor_search_service_solr', OkComputer::HttpCheck.new("#{solr_url}/admin/ping")

# OCR Queue Depth
OkComputer::Registry.register 'ocr_queue_depth', OcrQueueDepthCheck.new

# Bulk Metadata  services
OkComputer::Registry.register 'bulk_metadata_dir', OkComputer::DirectoryCheck.new(Settings.bulk_metadata.directory)
OkComputer::Registry.register 'bulk_metadata_tmp_dir',
                              OkComputer::DirectoryCheck.new(Settings.bulk_metadata.temporary_directory)
modsulator_url = "#{Settings.modsulator_url.split('v1').first}v1/about"
OkComputer::Registry.register 'modsulator_app', OkComputer::HttpCheck.new(modsulator_url)
OkComputer::Registry.register 'spreadsheet_url', OkComputer::HttpCheck.new(Settings.spreadsheet_url)
