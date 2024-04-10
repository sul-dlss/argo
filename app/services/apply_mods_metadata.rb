# frozen_string_literal: true

# Updates the metadata of an object with the given MODS
class ApplyModsMetadata
  # @param [String] apo_druid
  # @param [String] mods A string containing MODS XML.
  # @param [Cocina::Models::DRO] cocina the item to be updated
  # @param [String] original_filename the filename these updates came from
  # @param [Ability] ability the abilities of the acting user
  # @param [#puts] log
  def initialize(apo_druid:, mods:, cocina:, original_filename:, ability:, log:)
    @apo_druid = apo_druid
    @mods = mods
    @cocina = cocina
    @original_filename = original_filename
    @ability = ability
    @log = log
  end

  def can_apply?
    # Only update objects that are governed by the correct APO
    unless cocina.administrative.hasAdminPolicy == apo_druid
      log.puts("argo.bulk_metadata.bulk_log_apo_fail #{cocina.externalIdentifier}")
      return false
    end

    return false unless updatable?

    return false unless ability.can? :update, cocina

    # We only update objects if the cocina is different
    if cocina.description == cocina_description
      log.puts("argo.bulk_metadata.bulk_log_skipped_mods #{cocina.externalIdentifier}")
      return false
    end

    errors = ModsValidator.validate(mods_ng)
    if errors.present?
      log.puts "argo.bulk_metadata.bulk_log_validation_error #{cocina.externalIdentifier} #{errors.join(';')}"
      return false
    end

    true
  end

  def apply
    return unless can_apply?

    version_object
    begin
      update_metadata

      log.puts("argo.bulk_metadata.bulk_log_job_save_success #{cocina.externalIdentifier}")
    rescue Dor::Services::Client::UnexpectedResponse => e
      log.puts("argo.bulk_metadata.bulk_log_unexpected_response #{cocina.externalIdentifier} #{e.message}")
    end
  rescue Cocina::Models::ValidationError => e
    log.puts("argo.bulk_metadata.bulk_log_validation_error #{cocina.externalIdentifier} #{e.message}")
  rescue StandardError => e
    log_error!(e)
  end

  private

  attr_reader :apo_druid, :mods, :cocina, :original_filename, :ability, :log

  # Log the error
  def log_error!(exception)
    log.puts("argo.bulk_metadata.bulk_log_error_exception #{cocina.externalIdentifier}")
    log.puts(exception.message.to_s)
    log.puts(exception.backtrace.to_s)
  end

  # Open a new version for the given object if not already open
  def version_object
    open_version unless VersionService.open?(druid: cocina.externalIdentifier)
  end

  def update_metadata
    object_client = Dor::Services::Client.object(cocina.externalIdentifier)
    object_client.update(params: cocina.new(description: cocina_description))
  end

  # Open a new version for the given object.
  def open_version
    @cocina = VersionService.open(druid: cocina.externalIdentifier,
                                  description: "Descriptive metadata upload from #{original_filename}",
                                  opening_user_name: ability.current_user.sunetid)
  end

  # Item must be open or openable? to be updated
  def updatable?
    return true if VersionService.open?(druid: cocina.externalIdentifier) || VersionService.openable?(druid: cocina.externalIdentifier)

    log.puts("argo.bulk_metadata.bulk_log_skipped_mods #{cocina.externalIdentifier}")
    false
  end

  def cocina_description
    @cocina_description ||= Cocina::Models::Description.new(Cocina::Models::Mapping::FromMods::Description.props(mods: mods_ng, druid: cocina.externalIdentifier,
                                                                                                                 label: cocina.label))
  end

  def mods_ng
    @mods_ng ||= Nokogiri::XML(mods)
  end
end
