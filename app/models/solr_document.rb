# -*- encoding : utf-8 -*-
class SolrDocument 

  include Blacklight::Solr::Document

  # self.unique_key = 'id'
  
  # The following shows how to setup this blacklight document to display marc documents
  extension_parameters[:marc_source_field] = :marc_display
  extension_parameters[:marc_format_type] = :marcxml
  use_extension( Blacklight::Solr::Document::Marc) do |document|
    document.key?( :marc_display  )
  end
  
  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension( Blacklight::Solr::Document::Email )
  
  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension( Blacklight::Solr::Document::Sms )

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Solr::Document::ExtendableClassMethods#field_semantics
  # and Blacklight::Solr::Document#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension( Blacklight::Solr::Document::DublinCore)    
  field_semantics.merge!(    
                         :title => "title_display",
                         :author => "author_display",
                         :language => "language_facet",
                         :format => "format"
                         )
end
public
def get_milestones(doc)
  milestones = ActiveSupport::OrderedHash[
  'registered',   { :display => 'Registered',  :time => 'pending', :version =>1 },
  'submitted',    { :display => 'Submitted',   :time => 'pending', :version =>1 },
  'described',    { :display => 'Described',   :time => 'pending', :version =>1 },
  'published',    { :display => 'Published',   :time => 'pending', :version =>1 },
  'deposited',    { :display => 'Deposited',    :time => 'pending', :version =>1 },
  'accessioned',  { :display => 'Accessioned', :time => 'pending', :version =>1 },
  'indexed',      { :display => 'Indexed', :time => 'pending', :version =>1 },
  'ingested',     { :display => 'Ingested', :time => 'pending', :version =>1 }
]
#this needs to use the timezone set in config.time_zone
zone = ActiveSupport::TimeZone.new("Pacific Time (US & Canada)")
lifecycle_field = doc.has_key?('lifecycle_display') ? 'lifecycle_display' : 'lifecycle_facet'
  Array(doc[lifecycle_field]).each do |m| 
    if m.split(/:/).first.to_i>0 #if to_i >0 the first item in the split is an integer, meaning a version number
      (version,name,time) = m.split(/:/,3)
      milestones[name] ||= { :display => name.titleize, :time => 'pending' }
      milestones[name][:time] = DateTime.parse(time).in_time_zone(zone)
      milestones[name][:version]=version.to_i
    else
      (name,time) = m.split(/:/,2)
      milestones[name] ||= { :display => name.titleize, :time => 'pending' }
      milestones[name][:time] = DateTime.parse(time).in_time_zone(zone)
    end
  end
  return milestones
end
