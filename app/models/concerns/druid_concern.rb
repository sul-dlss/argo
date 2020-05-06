# frozen_string_literal: true

module DruidConcern
  extend Blacklight::Solr::Document

  ##
  # Access a SolrDocument's druid parsed from the id format of 'druid:abc123'
  # @return [String]
  def druid
    id.delete_prefix('druid:')
  end
end
