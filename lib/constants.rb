# frozen_string_literal: true

##
# A module for including constants throughout the Argo application
module Constants
  DEFAULT_RIGHTS_OPTIONS = Dor::RightsMetadataDS::RIGHTS_TYPE_CODES.map do |type_code, human_readable|
    [human_readable, type_code]
  end

  REGISTRATION_RIGHTS_OPTIONS = Dor::RightsMetadataDS::RIGHTS_TYPE_CODES.map do |type_code, human_readable|
    [human_readable, type_code == 'none' ? 'citation-only' : type_code]
  end

  CONTENT_TYPES = %w(image book file map media document 3d).freeze

  RESOURCE_TYPES = %w(image page file audio video document 3d).freeze

  RELEASE_TARGETS = [
    %w(Searchworks Searchworks),
    %w(Earthworks Earthworks)
  ].freeze
end
