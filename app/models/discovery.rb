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
        :field => "title_ssim",
        :sort => true, :default => true, :width => 200
      },
      {
        :label => "Format",
        :field => "sw_format_tesim",
        :default => true, :width => 200
      },
      {
        :label => "Variant Search Title",
        :field => "sw_title_variant_search_facet",
        :default => false, :width => 200
      },
      {
        :label => "Sort Title",
        :field => "title_sort_ssi",
        :default => false, :width => 200
      },
      {
        :label => "Full Display Title",
        :field => "title_ssim",
        :default => false, :width => 200
      },
      {
        :label => "Person Author Facet",
        :field => "sw_author_person_facet",
        :default => true, :width => 200
      },
      {
        :label => "Other Author Facet",
        :field => "sw_author_other_facet",
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
        :field => "topic_tesim",
        :default => false, :width => 200
      },
      {
        :label => "Geographic Search",
        :field => "sw_geographic_search_facet",
        :default => false, :width => 200
      },
      {
        :label => "Other Subject",
        :field => "sw_subject_other_search_facet",
        :default => false, :width => 200
      },
      {
        :label => "Other Subject Subvy",
        :field => "sw_subject_other_subvy_search_facet",
        :default => false, :width => 200
      },
      {
        :label => "Subject All",
        :field => "subject_topic_tesim",
        :default => false, :width => 200
      },
      {
        :label => "Topic Facet",
        :field => "topic_tesim",
        :default => false, :width => 200
      },
      {
        :label => "Geographic Facet",
        :field => "sw_geographic_facet",
        :default => false, :width => 200
      },
      {
        :label => "Era Facet",
        :field => "sw_era_facet",
        :default => false, :width => 200
      },
      {
        :label => "Language Facet",
        :field => "sw_language_tesim",
        :default => true, :width => 200
      },
      {
        :label => "Pub Place Search",
        :field => "sw_pub_search_facet",
        :default => false, :width => 200
      },
      {
        :label => "Pub Date Sort",
        :field => "sw_pub_date_sort_ssi",
        :default => false, :width => 200
      },
      {
        :label => "Pub Date Group Facet",
        :field => "sw_pub_date_facet_ssi",
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
      :qf => %{text^3 accessioned_day_tesim published_dttsim content_file_count_teim coordinates_teim creator_tesim dc_creator_si dc_identifier_druid_si dc_title_si dor_id_tesim event_t events_event_t events_t extent_teim identifier_tesim objectCreator_teim identityMetadata_otherId_t identityMetadata_sourceId_t lifecycle_sim originInfo_place_placeTerm_tesim originInfo_publisher_tesim obj_label_teim obj_state_teim originInfo_place_placeTerm_tesim originInfo_publisher_tesim otherId_t public_dc_contributor_tesim public_dc_coverage_tesim public_dc_creator_tesim public_dc_date_tesim public_dc_description_tesim public_dc_format_tesim public_dc_identifier_tesim public_dc_language_tesim public_dc_publisher_tesim public_dc_relation_tesim public_dc_rights_tesim public_dc_subject_tesim public_dc_title_tesim public_dc_type_tesim resource_count_display scale_teim shelved_content_file_count_display sourceId_t tag_teim title_tesim topic_tesim},
      :rows => 100,
      :facet => true,
      :'facet.mincount' => 1,
      :'f.wf_wps_ssim.facet.limit' => -1,
      :'f.wf_wsp_ssim.facet.limit' => -1,
      :'f.wf_swp_ssim.facet.limit' => -1,
      :fl => config.discovery_fields.collect { |f| f[:solr_fields] ||  f[:field] }.flatten.uniq.join(',')
    }

    config.add_sort_field 'id asc', :label => 'Druid'


    config.column_model = config.discovery_fields.collect { |spec|
      {
        'name'     => spec[:field],
        'jsonmap'  => spec[:field],
        'label'    => spec[:label],
        'index'    => spec[:field],
        'width'    => spec[:width],
        'sortable' => spec[:sort],
        'hidden'   => (not spec[:default])
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
      toret << rec['druid'].to_s+"\t"+rec['source_id_teim'].to_s
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
