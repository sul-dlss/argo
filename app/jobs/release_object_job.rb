# frozen_string_literal: true

##
# A background job to add a release tag and then start the release workflow
class ReleaseObjectJob < BulkActionJob
  def manage_release
    @manage_release ||= params.slice(:to, :who, :what, :tag)
  end

  class ReleaseObjectJobItem < BulkActionJobItem
    delegate :manage_release, to: :job

    def perform
      return unless check_update_ability?

      return failure!(message: 'Object has never been published and cannot be released') unless WorkflowService.published?(druid:)

      object_client.release_tags.create(tag: new_tag)
      object_client.workflow('releaseWF').create(version: cocina_object.version)

      success!(message: 'Workflow creation successful')
    end

    def object_client
      @object_client ||= Dor::Services::Client.object(druid)
    end

    def new_tag
      Dor::Services::Client::ReleaseTag.new(
        to: manage_release['to'],
        who: manage_release['who'],
        what: manage_release['what'],
        release: string_to_boolean(manage_release['tag']),
        date: DateTime.now.utc.iso8601
      )
    end

    def string_to_boolean(string)
      case string
      when 'true'
        true
      when 'false'
        false
      end
    end
  end
end
