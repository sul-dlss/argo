# frozen_string_literal: true

##
# A module for including constants throughout the Argo application
module Constants
  # From https://github.com/sul-dlss/dor-services/blob/master/lib/dor/datastreams/rights_metadata_ds.rb
  DEFAULT_RIGHTS_OPTIONS = [
    %w[World world],
    ['World (no-download)', 'world-nd'],
    %w[Stanford stanford],
    ['Stanford (no-download)', 'stanford-nd'],
    ['Controlled Digital Lending (no-download)', 'cdl-stanford-nd'],
    ['Location: Special Collections', 'loc:spec'],
    ['Location: Music Library', 'loc:music'],
    ['Location: Archive of Recorded Sound', 'loc:ars'],
    ['Location: Art Library', 'loc:art'],
    ['Location: Hoover Library', 'loc:hoover'],
    ['Location: Media & Microtext', 'loc:m&m'],
    ['Dark (Preserve Only)', 'dark'],
    ['Citation Only', 'none']
  ].freeze

  REGISTRATION_RIGHTS_OPTIONS = [
    %w[World world],
    ['World (no-download)', 'world-nd'],
    %w[Stanford stanford],
    ['Stanford (no-download)', 'stanford-nd'],
    ['Controlled Digital Lending (no-download)', 'cdl-stanford-nd'],
    ['Location: Special Collections', 'loc:spec'],
    ['Location: Music Library', 'loc:music'],
    ['Location: Archive of Recorded Sound', 'loc:ars'],
    ['Location: Art Library', 'loc:art'],
    ['Location: Hoover Library', 'loc:hoover'],
    ['Location: Media & Microtext', 'loc:m&m'],
    ['Dark (Preserve Only)', 'dark'],
    ['Citation Only', 'citation-only']
  ].freeze

  COLLECTION_RIGHTS_OPTIONS = [
    %w[World world],
    %w[Stanford stanford],
    ['Location: Special Collections', 'loc:spec'],
    ['Location: Music Library', 'loc:music'],
    ['Location: Archive of Recorded Sound', 'loc:ars'],
    ['Location: Art Library', 'loc:art'],
    ['Location: Hoover Library', 'loc:hoover'],
    ['Location: Media & Microtext', 'loc:m&m'],
    ['Dark (Preserve Only)', 'dark'],
    ['Citation Only', 'citation-only']
  ].freeze

  CONTENT_TYPES = %w[image book file map media document 3d].freeze

  RESOURCE_TYPES = %w[image page file audio video document 3d object].freeze

  RELEASE_TARGETS = [
    %w[Searchworks Searchworks],
    %w[Earthworks Earthworks]
  ].freeze
end
