# frozen_string_literal: true

module ResetSolr
  def self.reset_solr
    blacklight_config = CatalogController.blacklight_config
    solr_conn = blacklight_config.repository_class.new(blacklight_config).connection
    solr_conn.delete_by_query("*:*")
  end
end

if RSpec.respond_to?(:configure) # so this can be used by db:seed too.
  RSpec.configure do |config|
    config.before(:suite) { ResetSolr.reset_solr }
  end
end
