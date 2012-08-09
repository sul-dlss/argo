class Report
  include BlacklightSolrExtensions
  include Blacklight::Configurable
  include Blacklight::SolrHelper
  
  class << self
    include DorObjectHelper
    include ValueHelper
  end

  attr_reader :response, :document_list, :num_found

  @blacklight_config = blacklight_config.deep_copy if @blacklight_config.nil?
  
  configure_blacklight do |config|

    config.report_fields = [
      { 
        :label => "Druid", :field => 'druid', 
        :proc => lambda { |doc| doc['id'].split(/:/).last }, 
        :sort => true, :default => true, :width => 100 
      },
      { 
        :field => 'purl', :label => "Purl", 
        :proc => lambda { |doc| File.join(Argo::Config.urls.purl, doc['id'].split(/:/).last) }, 
        :solr_fields => ['id'],
        :sort => false, :default => false, :width => 100 
      },
      { 
        :field => 'title', :label => "Title", 
        :proc => lambda { |doc| retrieve_terms(doc)[:title] }, 
        :solr_fields => ['public_dc_title_t', 'mods_title_t', 'dc_title_t', 'obj_label_t'],
        :sort => false, :default => false, :width => 100 
      },
      { 
        :field => 'citation', :label => "Citation", 
        :proc => lambda { |doc| render_citation(doc) }, 
        :solr_fields => [
          'public_dc_creator_t', 'mods_creator_t', 'mods_name_t', 'dc_creator_t',
          'public_dc_title_t', 'mods_title_t', 'dc_title_t', 'obj_label_t',
          'mods_originInfo_place_placeTerm_t',
          'public_dc_publisher_t', 'mods_originInfo_publisher_t', 'dc_publisher_t',
          'public_dc_date_t', 'mods_dateissued_t', 'mods_datecreated_t', 'dc_date_t'
        ],
        :sort => false, :default => true, :width => 100 
      },
      { 
        :field => 'source_id_t', :label => "Source Id", 
        :sort => false, :default => true, :width => 100 
      },
      { 
        :field => 'apo_druid', :label => 'Admin. Policy ID', 
        :proc => lambda { |doc| doc['is_governed_by_s'].first.split(/:/).last }, 
        :sort => false, :default => false, :width => 100
      },
      { 
        :field => 'apo', :label => "Admin. Policy", 
        :proc => lambda { |doc| label_for_druid(doc['is_governed_by_s']) }, 
        :solr_fields => ['is_governed_by_s'],
        :sort => false, :default => true, :width => 100 
      },
      { 
        :field => 'collection_druid', :label => 'Collection ID', 
        :proc => lambda { |doc| doc['is_member_of_collection_s'].first.split(/:/).last }, 
        :sort => false, :default => false, :width => 100
      },
      { 
        :field => 'collection', :label => "Collection", 
        :proc => lambda { |doc| label_for_druid(doc['is_member_of_collection_s']) }, 
        :solr_fields => ['is_member_of_collection_s'],
        :sort => false, :default => false, :width => 100 
      },
      { 
        :field => 'project_tag_facet', :label => "Project", 
        :sort => true, :default => false, :width => 100 
      },
      { 
        :field => 'registered_by_facet', :label => "Registered By", 
        :sort => true, :default => false, :width => 100 
      },
      { 
        :field => 'tag_facet', :label => "Tags", 
        :sort => true, :default => false, :width => 100 
      },
      { 
        :field => 'objectType_facet', :label => "Object Type", 
        :sort => true, :default => false, :width => 100 
      },
      { 
        :field => 'content_type_facet', :label => "Content Type", 
        :sort => true, :default => false, :width => 100 
      },
#      { :field => , :label => "Location", :sort => true, :default => false, :width => 100 },
      { 
        :field => 'catkey_id_t', :label => "Catkey", 
        :sort => true, :default => false, :width => 100 
      },
      { 
        :field => 'barcode_id_t', :label => "Barcode", 
        :sort => true, :default => false, :width => 100 
      },
      { 
        :field => 'status', :label => "Status", 
        :proc => lambda { |doc| doc['lifecycle_facet'].last },
        :solr_fields => ['lifecycle_facet'],
        :sort => false, :default => true, :width => 100 
      },
      { 
        :field => 'published_dt', :label => "Pub. Date", 
          #modified to format the date
        :proc => lambda { |doc| Date.strptime(doc['published_dt'],'%Y-%m-%d %H:%M:%S')},
        :sort => true, :default => true, :width => 100 
      },
      { 
        :field => 'shelved_dt', :label => "Shelve Date", 
        :sort => true, :default => false, :width => 100 
      },
      { 
        :field => 'preserved_dt', :label => "Pres. Date", 
        :sort => true, :default => true, :width => 100 
      },
      { 
        :field => 'accessioned_dt', :label => "Accession. Date", 
        :sort => true, :default => false, :width => 100
      },
      { 
        :field => 'errors', :label => "Errors", 
        :proc => lambda { |doc| doc['workflow_status_display'].inject(0) { |sum,disp| sum += disp.split(/\|/).last.to_i } },
        :solr_fields => ['workflow_status_display'],
        :sort => true, :default => false, :width => 100 
      },
      {
        :field => 'file_count', :label => "Files",
        :proc => lambda { |doc| Array(doc['content_file_display']).length },
        :solr_fields => ['content_file_display'],
        :sort => false, :default => true, :width => 50
      },
      {
        :field => 'shelved_file_count', :label => "Shelved Files",
        :proc => lambda { |doc| Array(doc['shelved_content_file_display']).length },
        :solr_fields => ['shelved_content_file_display'],
        :sort => false, :default => true, :width => 50
      }
    ]
    config.default_solr_params = {
      :'q.alt' => "*:*",
      :defType => 'dismax',
      :qf => %{text^3 citationCreator_t citationTitle_t content_file_t coordinates_t creator_t dc_creator_t dc_identifier_t dc_title_t dor_id_t event_t events_event_t events_t extent_t identifier_t identityMetadata_citationCreator_t identityMetadata_citationTitle_t identityMetadata_objectCreator_t identityMetadata_otherId_t identityMetadata_sourceId_t lifecycle_t mods_originInfo_place_placeTerm_t mods_originInfo_publisher_t obj_label_t obj_state_t originInfo_place_placeTerm_t originInfo_publisher_t otherId_t public_dc_contributor_t public_dc_coverage_t public_dc_creator_t public_dc_date_t public_dc_description_t public_dc_format_t public_dc_identifier_t public_dc_language_t public_dc_publisher_t public_dc_relation_t public_dc_rights_t public_dc_subject_t public_dc_title_t public_dc_type_t scale_t shelved_content_file_t sourceId_t tag_t title_t topic_t},
      :rows => 10,
      :facet => true,
      :'facet.mincount' => 1,
      :'f.wf_wps_facet.facet.limit' => -1,
      :'f.wf_wsp_facet.facet.limit' => -1,
      :'f.wf_swp_facet.facet.limit' => -1,
      :fl => config.report_fields.collect { |f| f[:solr_fields] || f[:field] }.flatten.uniq.join(',')
    }

    config.column_model = config.report_fields.collect { |spec| 
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
      @fields = self.class.blacklight_config.report_fields
    else
      @fields = self.class.blacklight_config.report_fields.select { |f| fields.nil? or fields.include?(f[:field]) }
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
  
  def report_data
    docs_to_records(@document_list)
  end
  
  def each
    headers = @fields.collect { |f| f[:label] }
    yield FasterCSV::Row.new(headers,headers).to_csv
    while @document_list.length > 0
      records = docs_to_records(@document_list)
      records.each do |record|
        row = @fields.collect { |f| record[f[:field]] }
        yield FasterCSV::Row.new(headers,row).to_csv
      end
      @params[:page] += 1
      (@response, @document_list) = get_search_results
    end
  end
  
  protected
  def docs_to_records(docs, fields=blacklight_config.report_fields)
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