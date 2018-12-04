# frozen_string_literal: true

# Cannot just do:
#   ::ENABLE_SOLR_UPDATES = false
# Because "warning: already initialized constant ENABLE_SOLR_UPDATES".
# ActiveFedora assigns a default (if unassigned) and we cannot pre-empt it from here.

self.class.send(:remove_const, 'ENABLE_SOLR_UPDATES') if self.class.const_defined?('ENABLE_SOLR_UPDATES')
self.class.const_set('ENABLE_SOLR_UPDATES', false)
