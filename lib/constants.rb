##
# A module for including constants throughout the Argo application
module Constants
  DEFAULT_RIGHTS_OPTIONS = Dor::RightsMetadataDS::RIGHTS_TYPE_CODES.map do |type_code, human_readable|
    [human_readable, type_code]
  end

  # the name of the workflow that when selected from the initial workflow triggers an external workflow dropdown with options configured in registration_helper.rb
  DOR_EXTERNAL_WORKFLOW_NAME = 'goobiWF'

  # the name of the tag prefix that will be used to create the tag with the selected external workflow name (e.g. DPG : Workflow : Goobi_process_name)
  DOR_EXTERNAL_WORKFLOW_TAG_PREFIX = 'DPG : Workflow'

  CONTENT_TYPES = %w(image book file manuscript map media).freeze

  RESOURCE_TYPES = %w(image page file audio video).freeze

  RELEASE_TARGETS = [
    %w(Searchworks Searchworks)
  ].freeze
end
