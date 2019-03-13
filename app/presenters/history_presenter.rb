# frozen_string_literal: true

# Shows the history the workflow status
class HistoryPresenter
  def initialize(obj)
    @resource = obj
  end

  def versions
    version_list.each_with_object({}) do |rec, obj|
      (version, tag, desc) = rec.split(';')
      obj[version] = {
        tag: tag,
        desc: desc
      }
    end
  end

  def milestones
    lifecycle.each_with_object({}) do |m, milestones|
      (name, time) = m.split(/:/, 2)

      (time, version) = time.split(/;/, 2)
      version = 1 if version.blank?
      milestones[version] ||= ActiveSupport::OrderedHash[
        'registered' => {}, # each of these *could* have :display and :time elements
        'opened' => {},
        'submitted' => {},
        'described' => {},
        'published' => {},
        'deposited' => {},
        'accessioned' => {},
        'indexed' => {},
        'ingested' => {}
      ]
      milestones[version].delete(version == '1' ? 'opened' : 'registered') # only version 1 has 'registered'
      milestones[version][name] = {
        time: DateTime.parse(time)
      }
    end
  end

  private

  attr_reader :resource

  def lifecycle
    status_service = Dor::StatusService.new(resource)
    status_service.milestones.map do |milestone|
      timestamp = milestone[:at].utc.xmlschema
      "#{milestone[:milestone]}:#{timestamp};#{milestone[:version]}"
    end
  end

  def version_list
    return [] unless resource.respond_to?('versionMetadata')

    # add an entry with version id, tag and description for each version
    (1..resource.current_version.to_i).map do |current_version_num|
      "#{current_version_num};#{resource.versionMetadata.tag_for_version(current_version_num.to_s)};#{resource.versionMetadata.description_for_version(current_version_num.to_s)}"
    end
  end
end
