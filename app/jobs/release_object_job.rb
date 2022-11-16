# frozen_string_literal: true

##
# A background job to add a release tag and then start the release workflow
class ReleaseObjectJob < GenericJob
  attr_reader :manage_release

  ##
  # @param [Integer] bulk_action_id GlobalID for a BulkAction object
  # @param [Hash] params additional parameters that an Argo job may need
  # @option params [Array] :druids required list of druids
  # @option params [String] :to required release to target
  # @option params [String] :who required username of releaser
  # @option params [String] :what required type of release (self, collection)
  # @option params [String] :tag required (true, false)
  # @option params [Array] :groups the groups the user belonged to when the started the job. Required for permissions check
  def perform(bulk_action_id, params)
    super
    @manage_release = params.slice(:to, :who, :what, :tag)

    with_items(params[:druids], name: "Release tag") do |cocina_object, success, failure|
      next failure.call("Object has never been published and cannot be released") unless WorkflowService.published?(druid: cocina_object.externalIdentifier)
      next failure.call("Not authorized") unless ability.can?(:update, cocina_object)

      Repository.store(model_with_new_release_tag(cocina_object))

      WorkflowClientFactory.build.create_workflow_by_name(cocina_object.externalIdentifier, "releaseWF", version: cocina_object.version)
      success.call("Workflow creation successful")
    end
  end

  private

  # Return a copy of the existing cocina model with a new tag appended
  def model_with_new_release_tag(cocina)
    cocina.new(
      administrative: cocina.administrative.new(
        releaseTags: Array(cocina.administrative.releaseTags) + [new_tag]
      )
    )
  end

  def new_tag
    Cocina::Models::ReleaseTag.new(
      to: manage_release["to"],
      who: manage_release["who"],
      what: manage_release["what"],
      release: string_to_boolean(manage_release["tag"]),
      date: DateTime.now.utc.iso8601
    )
  end

  def string_to_boolean(string)
    case string
    when "true"
      true
    when "false"
      false
    end
  end
end
