# frozen_string_literal: true

class DecommissionService
  class DecommissionFailed < StandardError; end

  DECOMMISSION_ACCESS = { view: 'dark', download: 'none' }.freeze
  DECOMMISSION_APO = { hasAdminPolicy: 'druid:rm216bn3270' }.freeze

  attr_reader :druid, :reason, :sunetid

  def initialize(druid:, reason:, sunetid:)
    @druid = druid
    @reason = reason
    @sunetid = sunetid
  end

  def decommission
    version_service.open(druid:,
                         assume_accessioned: true,
                         description: "Decommissioned: #{reason}",
                         opening_user_name: sunetid)

    released_to.each do |release_target|
      release_tag = latest_release_tag_for(to: release_target)
      next unless release_tag.release

      object_client.release_tags.create(tag: release_tag.new(release: false))
    end

    structural = Cocina::Models::DROStructural.new(cocina_object.structural&.to_h&.except(:contains))
    updated_cocina = cocina_object.new(access: DECOMMISSION_ACCESS,
                                       administrative: DECOMMISSION_APO,
                                       structural:)

    Repository.store(updated_cocina)

    version_service.close(druid:,
                          description: "Decommissioned: #{reason}",
                          user_name: sunetid)

    object_client.administrative_tags.create(tags: ["Decommissioned : #{reason}"])
    object_client.reindex
  end

  private

  def cocina_object
    @cocina_object ||= Repository.find(druid)
  end

  def version_service
    @version_service ||= VersionService.new(druid:)
  end

  def object_client
    @object_client ||= Dor::Services::Client.object(druid)
  end

  def release_tags
    object_client.release_tags.list
  end

  def released_to
    release_tags.pluck(:to).uniq
  end

  def latest_release_tag_for(to:)
    release_tags.select { |tag| tag.to == to }.max_by(&:date)
  end
end
