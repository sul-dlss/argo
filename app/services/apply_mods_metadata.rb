# frozen_string_literal: true

# Updates the metadata of an object with the given MODS
class ApplyModsMetadata
  # @param [Nokogiri::XML::Element] mods_node A MODS XML node.
  # @param [Dor::Item] item the item to be updated
  def initialize(apo_druid:, mods_node:, item:, original_filename:, user_login:, log:)
    @apo_druid = apo_druid
    @mods_node = mods_node
    @item = item
    @original_filename = original_filename
    @user_login = user_login
    @log = log
  end

  def apply
    return unless item

    # Only update objects that are governed by the correct APO
    unless item.admin_policy_object_id == apo_druid
      log.puts("argo.bulk_metadata.bulk_log_apo_fail #{item_druid}")
      return
    end
    if in_accessioning?
      log.puts("argo.bulk_metadata.bulk_log_skipped_accession #{item_druid}")
      return
    end

    return unless status_ok?

    # We only update objects if the descMetadata XML is different
    current_metadata = item.descMetadata.content
    if equivalent_nodes(Nokogiri::XML(current_metadata).root, mods_node)
      log.puts("argo.bulk_metadata.bulk_log_skipped_mods #{item_druid}")
      return
    end

    version_object(original_filename, user_login, log)

    item.descMetadata.content = mods_node.to_s
    item.save!
    log.puts("argo.bulk_metadata.bulk_log_job_save_success #{item_druid}")
  rescue StandardError => e
    log.puts("argo.bulk_metadata.bulk_log_error_exception #{item_druid}")
    log.puts(e.message.to_s)
    log.puts(e.backtrace.to_s)
  end

  private

  attr_reader :apo_druid, :mods_node, :item, :original_filename, :user_login, :log

  # Open a new version for the given object if it is in the accessioned state.
  def version_object
    return unless accessioned?

    unless DorObjectWorkflowStatus.new(item.pid).can_open_version?
      log.puts("argo.bulk_metadata.bulk_log_unable_to_version #{item.pid}") # totally unexpected
      return
    end
    commit_new_version
  end

  # Open a new version for the given object.
  def commit_new_version
    vers_md_upd_info = {
      significance: 'minor',
      description: "Descriptive metadata upload from #{original_filename}",
      opening_user_name: user_login
    }
    VersionService.open(identifier: item.pid, vers_md_upd_info: vers_md_upd_info)
  end

  # Check if two MODS XML nodes are equivalent.
  #
  # @param [Nokogiri::XML::Element] node1 A MODS XML node.
  # @param [Nokogiri::XML::Element] node2 A MODS XML node.
  # @return [Boolean] true if the given nodes are equivalent, false otherwise.
  def equivalent_nodes(node1, node2)
    EquivalentXml.equivalent?(node1,
                              node2,
                              element_order: false,
                              normalize_whitespace: true,
                              ignore_attr_values: ['version', 'xmlns', 'xmlns:xsi', 'schemaLocation'])
  end

  # Returns true if the given object is accessioned, false otherwise.
  def accessioned?
    (6..8).cover?(status)
  end

  # Checks whether or not a DOR object is in accessioning or not.
  #
  # @return [Boolean]     true if the object is currently being accessioned, false otherwise
  def in_accessioning?
    (2..5).cover?(status)
  end

  # Checks whether or not a DOR object's status is OK for a descMetadata update. Basically, the only times we are
  # not OK to update is if the object is currently being accessioned and if the object has status unknown.
  #
  # @return [Boolean]     true if the object's status allows us to update the descMetadata datastream, false otherwise
  def status_ok?
    [1, 6, 7, 8, 9].include?(status)
  end

  # Returns the status_info for a DOR object from the StatusService
  #
  # @return [Integer]     value cooresponding to the status info list
  def status
    @status ||= Dor::StatusService.new(item).status_info[:status_code]
  end
end
