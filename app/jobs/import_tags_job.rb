# frozen_string_literal: true

##
# A job that imports tags from CSV for one or more objects
# @param [Integer] bulk_action_id GlobalID for a BulkAction object
# @param [Hash] params additional parameters that an Argo job may need
# @option params [String] :import_tags CSV string
class ImportTagsJob < BulkActionCsvJob
  def csv
    # CSV file doesn't contain headers, so providing here because druid column is required.
    @csv ||= CSV.parse(params[:csv_file], headers: ['druid'])
  end

  def druid_count
    csv.count { |row| row['druid'].present? }
  end

  class ImportTagsJobItem < BulkActionCsvJobItem
    def perform
      return if row['druid'].blank?

      tags = row.fields[1..].compact

      if tags.empty?
        destroy_tags
        success!(message: 'Destroyed all tags')
      else
        Dor::Services::Client.object(druid).administrative_tags.replace(tags:)
        success!(message: "Replaced tags (#{tags.join(', ')})")
      end
    end

    private

    def destroy_tags
      # dor-services-app does not currently allow replacing tags with an empty list, so delete them manually
      Dor::Services::Client.object(druid).administrative_tags.list.each do |tag|
        Dor::Services::Client.object(druid).administrative_tags.destroy(tag:)
      end
    end
  end

  # def perform(bulk_action_id, params)
  #   super

  #   with_bulk_action_log do |log_buffer|
  #     druids_with_tags = ImportTagsCsvConverter.convert(csv_string: params[:csv_file])

  #     # NOTE: We use this instead of `update_druid_count` because import
  #     #       tags does not use the `druids` form field.
  #     bulk_action.update(druid_count_total: druids_with_tags.count)

  #     druids_with_tags.each do |druid, tags|
  #       log_buffer.puts("#{Time.current} #{self.class}: Importing tags for #{druid} (bulk_action.id=#{bulk_action_id})")
  #       import_tags(druid, log_buffer, tags)
  #     end
  #   end
  # end

  private

  def import_tags(druid, log_buffer, tags)
    if tags.empty?
      # dor-services-app does not currently allow replacing tags with an empty list, so delete them manually
      Dor::Services::Client.object(druid).administrative_tags.list.each do |tag|
        Dor::Services::Client.object(druid).administrative_tags.destroy(tag:)
      end
    else
      Dor::Services::Client.object(druid).administrative_tags.replace(tags:)
    end
    # tags require immediate reindexing since they do not send messages to Solr
    Dor::Services::Client.object(druid).reindex
    bulk_action.increment(:druid_count_success).save
  rescue StandardError => e
    log_buffer.puts("#{Time.current} #{self.class}: Unexpected error importing tags for #{druid} (bulk_action.id=#{bulk_action.id}): #{e}")
    bulk_action.increment(:druid_count_fail).save
  end
end
