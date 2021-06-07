# frozen_string_literal: true

##
# A module for including constants throughout the Argo application
module Constants
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
    ['Dark (Preserve Only)', 'dark']
  ].freeze

  LICENSE_OPTIONS = [
    { label: 'Open Data Commons Public Domain Dedication and License 1.0',
      uri: 'https://opendatacommons.org/licenses/pddl/1-0/' },
    { label: 'Open Data Commons Attribution License 1.0',
      uri: 'https://opendatacommons.org/licenses/by/1-0/' },
    { label: 'Open Data Commons Open Database License 1.0',
      uri: 'https://opendatacommons.org/licenses/odbl/1-0/' },
    { label: 'No Rights Reserved',
      uri: 'https://creativecommons.org/publicdomain/zero/1.0/legalcode' },
    { label: 'Attribution 3.0 Unported',
      uri: 'https://creativecommons.org/licenses/by/3.0/legalcode' },
    { label: 'Attribution Share Alike 3.0 Unported',
      uri: 'https://creativecommons.org/licenses/by-sa/3.0/legalcode' },
    { label: 'Attribution No Derivatives 3.0 Unported',
      uri: 'https://creativecommons.org/licenses/by-nd/3.0/legalcode' },
    { label: 'Attribution Non-Commercial 3.0 Unported',
      uri: 'https://creativecommons.org/licenses/by-nc/3.0/legalcode' },
    { label: 'Attribution Non-Commercial Share Alike 3.0 Unported',
      uri: 'https://creativecommons.org/licenses/by-nc-sa/3.0/legalcode' },
    { label: 'Attribution Non-Commercial, No Derivatives 3.0 Unported',
      uri: 'https://creativecommons.org/licenses/by-nc-nd/3.0/legalcode' },
    { label: 'Public Domain Mark 1.0',
      uri: 'https://creativecommons.org/publicdomain/mark/1.0/' }
  ].freeze

  CONTENT_TYPES = {
    'book (ltr)' => Cocina::Models::Vocab.book,
    'book (rtl)' => Cocina::Models::Vocab.book,
    'file' => Cocina::Models::Vocab.object,
    'image' => Cocina::Models::Vocab.image,
    'map' => Cocina::Models::Vocab.map,
    'media' => Cocina::Models::Vocab.media,
    '3d' => Cocina::Models::Vocab.three_dimensional,
    'document' => Cocina::Models::Vocab.document,
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
