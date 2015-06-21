class Report
  include BlacklightSolrExtensions
  include Blacklight::Configurable
  include Blacklight::SolrHelper

  class << self
    include DorObjectHelper
    include ValueHelper
  end

  attr_reader :response, :document_list, :num_found, :params

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
        :solr_fields => %w(public_dc_title_tesim dc_title_tesim obj_label_ssim),
        :sort => false, :default => false, :width => 100
      },
      {
        :field => 'citation', :label => "Citation",
        :proc => lambda { |doc| render_citation(doc) },
        :solr_fields => %w(public_dc_creator_tesim dc_creator_tesim public_dc_title_tesim dc_title_tesim obj_label_ssim originInfo_place_placeTerm_tesim public_dc_publisher_tesim originInfo_publisher_tesim public_dc_date_tesim),
        :sort => false, :default => true, :width => 100
      },
      {
        :field => 'source_id_teim', :label => "Source Id",
        :sort => false, :default => true, :width => 100
      },
      {
        :field => 'is_governed_by_ssim', :label => 'Admin Policy ID',
        :proc => lambda { |doc| doc['is_governed_by_ssim'].first.split(/:/).last },
        :sort => false, :default => false, :width => 100
      },
      {
        :field => 'apo', :label => "Admin Policy",
        :proc => lambda { |doc| doc['apo_title_ssim'] },
        :solr_fields => ['apo_title_ssim'],
        :sort => false, :default => true, :width => 100
      },
      {
        :field => 'is_member_of_collection_ssim', :label => 'Collection ID',
        :proc => lambda { |doc| doc['is_member_of_collection_ssim'].map{|col| col.split(/:/).last }},
        :sort => false, :default => false, :width => 100
      },
      {
        :field => 'collection', :label => "Collection",
        :proc => lambda { |doc| doc['collection_title_ssim'] },
        :solr_fields => ['collection_title_ssim'],
        :sort => false, :default => false, :width => 100
      },
      {
        :field => 'project_tag_ssim', :label => "Project",
        :sort => true, :default => false, :width => 100
      },
      {
        :field => 'registered_by_tag_ssim', :label => "Registered By",
        :sort => true, :default => false, :width => 100
      },
      {
        :field => 'tag_ssim', :label => "Tags",
        :sort => true, :default => false, :width => 100
      },
      {
        :field => 'objectType_ssim', :label => "Object Type",
        :sort => true, :default => false, :width => 100
      },
      {
        :field => 'content_type_ssim', :label => "Content Type",
        :sort => true, :default => false, :width => 100
      },
#      { :field => , :label => "Location", :sort => true, :default => false, :width => 100 },
      {
        :field => 'catkey_id_ssim', :label => "Catkey",
        :sort => true, :default => false, :width => 100
      },
      {
        :field => 'barcode_id_ssim', :label => "Barcode",
        :sort => true, :default => false, :width => 100
      },
      {
        :field => 'status_ssm', :label => "Status",
        :sort => false, :default => true, :width => 100
      },
      {
        :field => 'published_datetime', :label => "Pub. Datetime",
          #modified to format the date
        :proc => lambda { |doc| render_datetime(doc['published_dttsim'])},
        :solr_fields => ['published_dttsim'],
        :sort => true, :default => false, :width => 100
      },
      {
        :field => 'registered_datetime', :label => "Reg. Datetime",
        :proc => lambda { |doc| render_datetime(doc['registered_dt'])},
        :solr_fields => ['preserved_dt'],
        :sort => true, :default => false, :width => 100
      },
      {
        :field => 'preserved_datetime', :label => "Pres. Datetime",
        :proc => lambda { |doc| render_datetime(doc['preserved_dt'])},
        :solr_fields => ['preserved_dt'],
        :sort => true, :default => false, :width => 100
      },
      {
        :field => 'accessioned_datetime', :label => "Accession. Datetime",
        :proc => lambda { |doc| render_datetime(doc['accessioned_dt'])},
        :solr_fields => ['accessioned_dt'],
        :sort => true, :default => false, :width => 100
      },
      {
        :field => 'registered_dt', :label => "Reg. Date",
          #modified to format the date
        :proc => lambda { |doc| doc['registered_day_facet']},
        :solr_fields => ['registered_day_facet'],
        :sort => true, :default => true, :width => 100
      },
      {
        :field => 'published_dt', :label => "Pub. Date",
          #modified to format the date
        :proc => lambda { |doc| doc['published_dttsim']},
        :solr_fields => ['published_dttsim'],
        :sort => true, :default => true, :width => 100
      },
      {
        :field => 'accessioned_dt', :label => "Accession. Date",
        :proc => lambda { |doc| doc['accessioned_day_tesim']},
        :solr_fields => ['accessioned_day_tesim'],
        :sort => true, :default => false, :width => 100
      },
      {
        :field => 'workflow_status_display', :label => "Errors",
        :proc => lambda { |doc| doc['workflow_status_ssim'].first.split('|')[2] },
        :solr_fields => ['workflow_status_ssim'],
        :sort => true, :default => false, :width => 100
      },
      {
        :field => 'file_count', :label => "Files",
        :proc => lambda { |doc| doc['content_file_count_display'] },
        :solr_fields => ['content_file_count_display'],
        :sort => false, :default => true, :width => 50
      },
      {
        :field => 'shelved_file_count', :label => "Shelved Files",
        :proc => lambda {|doc| doc['shelved_content_file_count_display'] },
        :solr_fields => ['shelved_content_file_count_display'],
        :sort => false, :default => true, :width => 50
      },
      {
        :field => 'resource_count', :label => "Resources",
        :proc => lambda {|doc| doc['resource_count_display'] },
        :solr_fields => ['resource_count_display'],
        :sort => false, :default => true, :width => 50
      },
      {
        :field => 'preserved_size', :label => "Preservation Size",
        :proc => lambda { |doc| doc['preserved_size_display'] },
        :solr_fields => ['preserved_size_display'],
        :sort => false, :default => true, :width => 50
      }

    ]
    config.default_solr_params = {
      :'q.alt' => "*:*",
      :defType => 'dismax',
      :qf => %{text^3 accessioned_day_tesim preserved_day_facet shelved_day_facet published_dttsim content_file_count_display coordinates_teim creator_tesim dc_creator_tesim dc_identifier_druid_tesim dc_title_tesim dor_id_tesim event_t events_event_t events_t extent_teim identifier_tesim objectCreator_teim identityMetadata_otherId_t identityMetadata_sourceId_t lifecycle_teim originInfo_place_placeTerm_tesim originInfo_publisher_tesim obj_label_tesim obj_state_tesim otherId_t public_dc_contributor_tesim public_dc_coverage_tesim public_dc_creator_tesim public_dc_date_tesim public_dc_description_tesim public_dc_format_tesim public_dc_identifier_tesim public_dc_language_tesim public_dc_publisher_tesim public_dc_relation_tesim public_dc_rights_tesim public_dc_subject_tesim public_dc_title_tesim public_dc_type_tesim resource_count_display scale_teim shelved_content_file_count_display sourceId_t tag_ssim title_tesim topic_tesim is_member_of_collection_ssim is_governed_by_ssim},
      :rows => 100,
      :facet => true,
      :'facet.mincount' => 1,
      :'f.wf_wps_ssim.facet.limit' => -1,
      :'f.wf_wsp_ssim.facet.limit' => -1,
      :'f.wf_swp_ssim.facet.limit' => -1,
      :fl => config.report_fields.collect { |f| f[:solr_fields] ||  f[:field] }.flatten.uniq.join(',')
    }
    config.add_sort_field 'id asc', :label => 'Druid'


    config.column_model = config.report_fields.collect { |spec|
      {
        'name' => spec[:field],
        'jsonmap' => spec[:field],
        'label' => spec[:label],
        'index' => spec[:field],
        'width' => spec[:width],
        'sortable' => spec[:sort],
        'hidden' => (!spec[:default])
      }
    }
  end

  def initialize(params = {}, fields=nil)
    if fields.nil?
      @fields = self.class.blacklight_config.report_fields
    else
      @fields = self.class.blacklight_config.report_fields.select { |f| fields.nil? || fields.include?(f[:field]) }
      @fields.sort! { |a,b| fields.index(a[:field]) <=> fields.index(b[:field]) }
    end
    @params = params
    @params[:page] ||= 1

    (@response, @document_list) = get_search_results
    @num_found = @response['response']['numFound'].to_i
  end

  def pids params
    @params[:page] = 1
    params[:per_page] = 100
    (@response, @document_list) = get_search_results
    toret=[]
    while @document_list.length > 0
      report_data.each do |rec|
        if params[:source_id]
          toret << rec['druid'].to_s+"\t"+rec['source_id_teim'].to_s
        elsif params[:tags]
          tags=''
          if !rec['tag_ssim'].nil?
            rec['tag_ssim'].split(';').each do |tag|
              tags+="\t"+tag.to_s
            end
          end
          toret << rec['druid']+tags
        else
          toret << rec['druid']
        end
      end
      @params[:page] += 1
      (@response, @document_list) = get_search_results
    end

    return toret
  end

  def report_data
    docs_to_records(@document_list)
  end

  def csv2
    @params[:page] = 1
    headings=''
    rows=''
    @fields.each do |f|
      headings+=f[:label]+","
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
  def docs_to_records(docs, fields=blacklight_config.report_fields)
    result = []
    docs.each_with_index do |doc,index|
      row = Hash[fields.collect do |spec|
        val = spec.key?(:proc) ? spec[:proc].call(doc) : doc[spec[:field]] rescue nil
        val = val.join('; ') if val.is_a?(Array)
        [spec[:field],val]
      end]
      row['id'] = index + 1
      result << row
    end
    result
  end

end
