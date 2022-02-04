# frozen_string_literal: true

# Updates the metadata of an object with the given MODS
class ApplyModsMetadata
  # @param [String] apo_druid
  # @param [String] mods A string containing MODS XML.
  # @param [Cocina::Models::DRO] cocina the item to be updated
  # @param [String] existing_mods A string containing the current descriptive metadata for the object.
  # @param [String] original_filename the filename these updates came from
  # @param [Ability] ability the abilities of the acting user
  # @param [#puts] log
  def initialize(apo_druid:, mods:, existing_mods:, cocina:, original_filename:, ability:, log:)
    @apo_druid = apo_druid
    @mods = mods
    @existing_mods = existing_mods
    @cocina = cocina
    @original_filename = original_filename
    @ability = ability
    @log = log
  end

  def apply
    # Only update objects that are governed by the correct APO
    unless cocina.administrative.hasAdminPolicy == apo_druid
      log.puts("argo.bulk_metadata.bulk_log_apo_fail #{cocina.externalIdentifier}")
      return
    end

    if in_accessioning?
      log.puts("argo.bulk_metadata.bulk_log_skipped_accession #{cocina.externalIdentifier}")
      return
    end

    return unless status_ok?

    return unless ability.can? :manage_item, cocina

    # We only update objects if the descMetadata XML is different
    if equivalent_xml?(existing_mods, mods)
      log.puts("argo.bulk_metadata.bulk_log_skipped_mods #{cocina.externalIdentifier}")
      return
    end

    errors = ModsValidator.validate(Nokogiri::XML(mods))
    if errors.present?
      log.puts "argo.bulk_metadata.bulk_log_validation_error #{cocina.externalIdentifier} #{errors.join(';')}"
      return
    end

    version_object
    update_metadata

    log.puts("argo.bulk_metadata.bulk_log_job_save_success #{cocina.externalIdentifier}")
  rescue StandardError => e
    log_error!(e)
  end

  private

  attr_reader :apo_druid, :mods, :existing_mods, :cocina, :original_filename, :ability, :log

  # Log the error
  def log_error!(exception)
    log.puts("argo.bulk_metadata.bulk_log_error_exception #{cocina.externalIdentifier}")
    log.puts(exception.message.to_s)
    log.puts(exception.backtrace.to_s)
  end

  # Open a new version for the given object if it is in the accessioned state.
  def version_object
    return unless accessioned?

    unless DorObjectWorkflowStatus.new(cocina.externalIdentifier, version: cocina.version).can_open_version?
      log.puts("argo.bulk_metadata.bulk_log_unable_to_version #{cocina.externalIdentifier}") # totally unexpected
      return
    end
    commit_new_version
  end

  def update_metadata
    object_client = Dor::Services::Client.object(cocina.externalIdentifier)
    object_client.metadata.update_mods(mods)
  end

  # Open a new version for the given object.
  def commit_new_version
    VersionService.open(identifier: cocina.externalIdentifier,
                        significance: 'minor',
                        description: "Descriptive metadata upload from #{original_filename}",
                        opening_user_name: ability.current_user.sunetid)
  end

  # Check if two MODS XML nodes are equivalent.
  #
  # @param [Nokogiri::XML::Element] node1 A MODS XML node.
  # @param [Nokogiri::XML::Element] node2 A MODS XML node.
  # @return [Boolean] true if the given nodes are equivalent, false otherwise.
  def equivalent_xml?(node1, node2)
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
  # @return [Boolean] true if the object is currently being accessioned, false otherwise
  def in_accessioning?
    (2..5).cover?(status)
  end

  # Checks whether or not a DOR object's status is OK for a descMetadata update. Basically, the only times we are
  # not OK to update is if the object is currently being accessioned and if the object has status unknown.
  #
  # @return [Boolean] true if the object's status allows us to update the descMetadata datastream, false otherwise
  def status_ok?
    [1, 6, 7, 8, 9].include?(status)
  end

  # Returns the status code for a DOR object
  #
  # @return [Integer] value corresponding to the status info list
  def status
    # We must provide a string version here: https://github.com/sul-dlss/dor-workflow-client/issues/169
    @status ||= WorkflowClientFactory.build.status(druid: cocina.externalIdentifier, version: cocina.version.to_s).info[:status_code]
  end
end
