# frozen_string_literal: true

# Draws a row for a datastream
class DatastreamRow < ApplicationComponent
  # @param [SolrDocument] document the Solr document model for the item
  # @param [Hash] attributes the datastream attributes
  def initialize(document:, attributes:)
    @document = document
    @specs = attributes
  end

  attr_reader :document, :specs

  # Datastream helpers
  CONTROL_GROUP_TEXT = { 'X' => 'inline', 'M' => 'managed', 'R' => 'redirect', 'E' => 'external' }.freeze

  def control_group
    cg = specs.fetch(:control_group, 'X')
    "#{cg}/#{CONTROL_GROUP_TEXT[cg]}"
  end

  def link_to_identifier
    link_to specs[:dsid], ds_solr_document_path(document, specs[:dsid]), title: specs[:dsid], data: { behavior: 'persistent-modal' }
  end

  def mime_type
    specs[:mime_type]
  end

  def version
    "v#{specs[:version]}"
  end

  def size
    number_to_human_size(specs[:size])
  end

  def label
    specs[:label]
  end
end
