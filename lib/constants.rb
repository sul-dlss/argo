##
# A module for including constants throughout the Argo application
module Constants
  DEFAULT_RIGHTS_OPTIONS = [
    ['World', 'world'],
    ['World (no-download)', 'world-nd'],
    ['Stanford', 'stanford'],
    ['Stanford (no-download)', 'stanford-nd'],
    ['Location spec', 'loc:spec'],
    ['Location music', 'loc:music'],
    ['Dark (Preserve Only)', 'dark'],
    ['Citation Only', 'none']
  ]
  CONTENT_TYPES = %w(image book file manuscript map media).freeze
  RESOURCE_TYPES = %w(image page file audio video).freeze
  RELEASE_TARGETS = [
    %w(Searchworks Searchworks)
  ].freeze
end
