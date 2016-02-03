##
# A module for including constants throughout the Argo application
module Constants
  DEFAULT_RIGHTS_OPTIONS = [
    %w(World world),
    %w(Stanford stanford),
    ['Dark (Preserve Only)', 'dark'],
    ['Citation Only', 'none']
  ]
  CONTENT_TYPES = %w(image book file manuscript map media).freeze
  RESOURCE_TYPES = %w(image page file audio video).freeze
end
