class IndexingException < ActiveRecord::Base
  attr_accessible :dor_services_version, :exception, :pid, :solr_document

  before_validation :set_dor_services_version

  def set_dor_services_version
    self.dor_services_version = Dor::VERSION
  end
end
