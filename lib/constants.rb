# frozen_string_literal: true

##
# A module for including constants throughout the Argo application
module Constants
  # From https://github.com/sul-dlss/dor-services/blob/main/lib/dor/datastreams/rights_metadata_ds.rb
  # Currently these are only used by the CollectionForm
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

  CONTENT_TYPES = {
    'image' => Cocina::Models::Vocab.image,
    'book' => Cocina::Models::Vocab.book,
    'file' => Cocina::Models::Vocab.object,
    'map' => Cocina::Models::Vocab.map,
    'media' => Cocina::Models::Vocab.media,
    'document' => Cocina::Models::Vocab.document,
    '3d' => Cocina::Models::Vocab.three_dimensional,
    'geo' => Cocina::Models::Vocab.geo,
    'webarchive-seed' => Cocina::Models::Vocab.webarchive_seed
  }.freeze

  RESOURCE_TYPES = {
    'image' => Cocina::Models::Vocab::Resources.image,
    'page' => Cocina::Models::Vocab::Resources.page,
    'file' => Cocina::Models::Vocab::Resources.file,
    'audio' => Cocina::Models::Vocab::Resources.audio,
    'video' => Cocina::Models::Vocab::Resources.video,
    'document' => Cocina::Models::Vocab::Resources.document,
    '3d' => Cocina::Models::Vocab::Resources.three_dimensional,
    'object' => Cocina::Models::Vocab::Resources.object
  }.freeze

  RELEASE_TARGETS = [
    %w[Searchworks Searchworks],
    %w[Earthworks Earthworks]
  ].freeze
end
