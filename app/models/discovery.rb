class Discovery
  include BlacklightSolrExtensions
  include Blacklight::Configurable
  include Blacklight::SolrHelper
  
  attr_reader :response, :document_list, :num_found
  
  configure_blacklight do |config|

    config.discovery_fields = [
      { 
        :label => "Druid", :field => 'druid', 
        :proc => lambda { |doc| 
          doc['id'].split(/:/).last }, 
        :sort => true, :default => true, :width => 100
      },
      { 
        :label => "Druid", :field => 'id', 
        :sort => true, :default => false, :width => 100
      },
      {
        :label => "Display Title",
        :field => "sw_title_display_facet",
        :sort => true, :default => true, :width => 200
      },
      {
        :label => "Format",
        :field => "sw_format_facet",
        :default => true, :width => 200 
      },
      {
        :label => "245a Search Title",
        :field => "sw_title_245a_search_facet_facet",
        :default => false, :width => 200 
      },
      {
        :label => "245 Search Title",
        :field => "sw_title_245_search_facet_facet",
        :default => false, :false => 200 
      },
      {
        :label => "Variant Search Title",
        :field => "sw_title_variant_search_facet_facet",
        :default => false, :width => 200 
      },
      {
        :label => "Sort Title",
        :field => "sw_title_sort_facet",
        :default => false, :width => 200 
      },
      {
        :label => "245a Display Title",
        :field => "sw_title_245a_display_facet",
        :default => false, :width => 200 
      },
      {
        :label => "Full Display Title",
        :field => "sw_title_full_display_facet",
        :default => false, :width => 200 
      },
      {
        :label => "1xx Search Author",
        :field => "sw_author_1xx_search_facet_facet",
        :default => false, :width => 200 
      },
      {
        :label => "7xx Search Author",
        :field => "sw_author_7xx_search_facet_facet",
        :default => false, :width => 200 
      },
      {
        :label => "Person Author Facet",
        :field => "sw_author_person_facet_facet",
        :default => true, :width => 200 
      },
      {
        :label => "Other Author Facet",
        :field => "sw_author_other_facet_facet",
        :default => false, :width => 200 
      },
      {
        :label => "Corporate Author Display",
        :field => "sw_author_corp_display_facet",
        :default => false, :width => 200 
      },
      {
        :label => "Author Meeting Display",
        :field => "sw_author_meeting_display_facet",
        :default => false, :width => 200 
      },
      {
        :label => "Person Author Display",
        :field => "sw_author_person_display_facet",
        :default => false, :width => 200 
      },
      {
        :label => "Person Author Full Display",
        :field => "sw_author_person_full_display_facet",
        :default => false, :width => 200 
      },
      {
        :label => "Topic Search",
        :field => "sw_topic_search_facet_facet",
        :default => false, :width => 200 
      },
      {
        :label => "Geographic Search",
        :field => "sw_geographic_search_facet_facet",
        :default => false, :width => 200 
      },
      {
        :label => "Other Subject",
        :field => "sw_subject_other_search_facet_facet",
        :default => false, :width => 200 
      },
      {
        :label => "Other Subject Subvy",
        :field => "sw_subject_other_subvy_search_facet_facet",
        :default => false, :width => 200 
      },
      {
        :label => "Subject All",
        :field => "sw_subject_all_search_facet_facet",
        :default => false, :width => 200 
      },
      {
        :label => "Topic Facet",
        :field => "sw_topic_facet_facet",
        :default => false, :width => 200 
      },
      {
        :label => "Geographic Facet",
        :field => "sw_geographic_facet_facet",
        :default => false, :width => 200 
      },
      {
        :label => "Era Facet",
        :field => "sw_era_facet_facet",
        :default => false, :width => 200 
      },
      {
        :label => "Language Facet",
        :field => "sw_language_facet",
        :default => true, :width => 200 
      },
      {
        :label => "Pub Place Search",
        :field => "sw_pub_search_facet_facet",
        :default => false, :width => 200 
      },
      {
        :label => "Pub Date Sort",
        :field => "sw_pub_date_sort_facet",
        :default => false, :width => 200 
      },
      {
        :label => "Pub Date Group Facet",
        :field => "sw_pub_date_group_facet_facet",
        :default => false, :width => 200 
      },

      {
        :label => "Pub Year Facet",
        :field => "sw_pub_date_facet",
        :default => true, :width => 200 
      },
      {
        :label => "Pub Date Display",
        :field => "sw_pub_date_display_facet",
        :default => true, :width => 200 
      }
    ]
    config.default_solr_params = {
      :'q.alt' => "*:*",
      :defType => 'dismax',
      :qf => %{text^3 accessioned_day_facet preserved_day_facet shelved_day_facet shelved_day_facet published_day_facet citationCreator_t citationTitle_t content_file_count_display coordinates_t creator_t dc_creator_t dc_identifier_t dc_title_t dor_id_t event_t events_event_t events_t extent_t identifier_t identityMetadata_citationCreator_t identityMetadata_citationTitle_t identityMetadata_objectCreator_t identityMetadata_otherId_t identityMetadata_sourceId_t lifecycle_t mods_originInfo_place_placeTerm_t mods_originInfo_publisher_t obj_label_t obj_state_t originInfo_place_placeTerm_t originInfo_publisher_t otherId_t public_dc_contributor_t public_dc_coverage_t public_dc_creator_t public_dc_date_t public_dc_description_t public_dc_format_t public_dc_identifier_t public_dc_language_t public_dc_publisher_t public_dc_relation_t public_dc_rights_t public_dc_subject_t public_dc_title_t public_dc_type_t resource_count_display scale_t shelved_content_file_count_display sourceId_t tag_t title_t topic_t},
      :rows => 100,
      :facet => true,
      :'facet.mincount' => 1,
      :'f.wf_wps_facet.facet.limit' => -1,
      :'f.wf_wsp_facet.facet.limit' => -1,
      :'f.wf_swp_facet.facet.limit' => -1,
      :fl => config.discovery_fields.collect { |f| f[:solr_fields] ||  f[:field] }.flatten.uniq.join(',')
    }
    
    config.add_sort_field 'id asc', :label => 'Druid'
    

    config.column_model = config.discovery_fields.collect { |spec| 
      { 
        'name' => spec[:field],
        'jsonmap' => spec[:field],
        'label' => spec[:label],
        'index' => spec[:field],
        'width' => spec[:width],
        'sortable' => spec[:sort],
        'hidden' => (not spec[:default])
      } 
    }
  end

  def initialize(params = {}, fields=nil)
    if fields.nil?
      @fields = self.class.blacklight_config.discovery_fields
    else
      @fields = self.class.blacklight_config.discovery_fields.select { |f| fields.nil? or fields.include?(f[:field]) }
      @fields.sort! { |a,b| fields.index(a[:field]) <=> fields.index(b[:field]) }
    end
    @params = params
    @params[:page] ||= 1
    
    (@response, @document_list) = get_search_results
    @num_found = @response['response']['numFound'].to_i
  end
  
  def params
    @params
  end
  def pids params
    toret=[]
    while @document_list.length >0
    report_data.each do|rec|
    if params[:source_id]
      toret << rec['druid'].to_s+"\t"+rec['source_id_t'].to_s
    else
      toret << rec['druid']
    end
    end
    @params[:page] += 1
    (@response, @document_list) = get_search_results
  end
    toret
  end
  def report_data
    docs_to_records(@document_list)
  end
  
  def csv2
    headings=''
    rows=''
    @fields.each do |f|
      label=f[:label] ? f[:label] : f[:field]
      headings+=label+","
    end

    while @document_list.length >0
      records=docs_to_records(@document_list)
      records.each do |record|
        rows+="\r\n"
        row = @fields.collect { |f| record[f[:field]] }
        row.each do |field|
          rows << '"'+field.to_s+'"'+','
        end
      end
      @params[:page] += 1
      (@response, @document_list) = get_search_results      
    end
    return headings+rows
  end

  protected
  def docs_to_records(docs, fields=blacklight_config.discovery_fields)
    result = []
    docs.each_with_index do |doc,index|
      row = Hash[fields.collect do |spec|
        val = spec.has_key?(:proc) ? spec[:proc].call(doc) : doc[spec[:field]] rescue nil
        val = val.join('; ') if val.is_a?(Array)
        [spec[:field],val]
      end]
      row['id'] = index + 1
      result << row
    end
    result
  end
end