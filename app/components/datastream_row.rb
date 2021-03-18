# frozen_string_literal: true

# Draws a row for a datastream
class DatastreamRow < ApplicationComponent
  with_collection_parameter :datastream

  # @param [ActiveFedora::Datastream] datastream
  def initialize(datastream:)
    @datastream = datastream
  end

  attr_reader :datastream

  delegate :label, :dsid, :pid, :versionId, to: :datastream

  def link_to_identifier
    link_to dsid, item_datastream_path(pid, dsid), title: dsid, data: { blacklight_modal: 'trigger' }
  end

  def size
    number_to_human_size(datastream.size)
  end

  def mime_type
    datastream.mimeType
  end
end
