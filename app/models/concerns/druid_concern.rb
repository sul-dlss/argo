module DruidConcern
  extend Blacklight::Solr::Document

  ##
  # Access a SolrDocument's druid parsed from the id format of 'druid:abc123'
  # @return [String]
  def druid
    id.split(/:/).last
  end
end
