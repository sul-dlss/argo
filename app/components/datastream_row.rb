# frozen_string_literal: true

# Draws a row for a datastream
class DatastreamRow < ApplicationComponent
  with_collection_parameter :datastream

  # @param [ActiveFedora::Datastream] datastream
  def initialize(datastream:)
    @datastream = datastream
  end

  attr_reader :datastream

  delegate :label, :dsid, :pid, to: :datastream

  # Datastream helpers
  CONTROL_GROUP_TEXT = { 'X' => 'inline', 'M' => 'managed', 'R' => 'redirect', 'E' => 'external' }.freeze

  def control_group
    "#{datastream.controlGroup}/#{CONTROL_GROUP_TEXT[datastream.controlGroup]}"
  end

  def link_to_identifier
    link_to dsid, item_datastream_path(pid, dsid), title: dsid, data: { blacklight_modal: 'trigger' }
  end

  def size
    number_to_human_size(datastream.size)
  end

  def mime_type
    datastream.mimeType
  end

  def version
    v = datastream.versionID.nil? ? '0' : datastream.versionID.to_s.split(/\./).last
    "v#{v}"
  end
end
