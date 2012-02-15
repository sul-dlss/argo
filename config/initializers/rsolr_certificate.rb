# Force Blacklight to use Dor:RSolrConnection, which supports client certificates
require 'dor/rsolr'
Blacklight.instance_variable_set(:@solr, RSolr::Ext.connect(Dor::RSolrConnection, Blacklight.solr_config))
