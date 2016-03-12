class Report
  include Blacklight::Configurable
  include Blacklight::SearchHelper
  include CsvConcern
  include DateFacetConfigurations

  class << self
    include DorObjectHelper
    include ValueHelper
  end

  attr_reader :response, :document_list, :num_found, :params, :current_user

  @blacklight_config = blacklight_config.deep_copy if @blacklight_config.nil?

  configure_blacklight do |config|

    config.report_fields = [
      {
        :field => :druid, :label => 'Druid',
        :proc => lambda { |doc| doc['id'].split(/:/).last },
        :sort => true, :default => true, :width => 100
      },
      {
        :field => :purl, :label => 'Purl',
        :proc => lambda { |doc| File.join(Settings.PURL_URL, doc['id'].split(/:/).last) },
        :solr_fields => %w(id),
        :sort => false, :default => false, :width => 100
      },
      {
        :field => :title, :label => 'Title',
        :proc => lambda { |doc| retrieve_terms(doc)[:title] },
        :solr_fields => %w(public_dc_title_tesim dc_title_tesim obj_label_ssim),
        :sort => false, :default => false, :width => 100
      },
      {
        :field => :citation, :label => 'Citation',
        :proc => lambda { |doc| render_citation(doc) },
        :solr_fields => %w(public_dc_creator_tesim dc_creator_tesim public_dc_title_tesim dc_title_tesim obj_label_ssim originInfo_place_placeTerm_tesim public_dc_publisher_tesim originInfo_publisher_tesim public_dc_date_tesim),
        :sort => false, :default => true, :width => 100
      },
      {
        :field => :source_id_ssim, :label => 'Source Id',
        :sort => false, :default => true, :width => 100
      },
      {
        :field => SolrDocument::FIELD_APO_ID, :label => 'Admin Policy ID',
        :proc => lambda { |doc| doc[SolrDocument::FIELD_APO_ID].first.split(/:/).last },
        :sort => false, :default => false, :width => 100
      },
      {
        :field => SolrDocument::FIELD_APO_TITLE, :label => 'Admin Policy',
        :sort => false, :default => true, :width => 100
      },
      {
        :field => SolrDocument::FIELD_COLLECTION_ID, :label => 'Collection ID',
        :proc => lambda { |doc| doc[SolrDocument::FIELD_COLLECTION_ID].map{|id| id.split(/:/).last } },
        :sort => false, :default => false, :width => 100
      },
      {
        :field => SolrDocument::FIELD_COLLECTION_TITLE, :label => 'Collection',
        :proc => lambda { |doc| doc[SolrDocument::FIELD_COLLECTION_TITLE].join(',') },
        :sort => false, :default => false, :width => 100
      },
      {
        :field => :project_tag_ssim, :label => 'Project',
        :sort => true, :default => false, :width => 100
      },
      {
        :field => :registered_by_tag_ssim, :label => 'Registered By',
        :sort => true, :default => false, :width => 100
      },
      {
        :field => :registered_earliest_dttsi, :label => 'Registered',
        :proc => lambda { |doc| render_datetime(doc[:registered_earliest_dttsi])},
        :sort => true, :default => false, :width => 100
      },
      {
        :field => :tag_ssim, :label => 'Tags',
        :sort => true, :default => false, :width => 100
      },
      {
        :field => :objectType_ssim, :label => 'Object Type',
        :sort => true, :default => false, :width => 100
      },
      {
        :field => :content_type_ssim, :label => 'Content Type',
        :sort => true, :default => false, :width => 100
      },
      {
        :field => SolrDocument::FIELD_CATKEY_ID, :label => 'Catkey',
        :sort => true, :default => false, :width => 100
      },
      {
        :field => :barcode_id_ssim, :label => 'Barcode',
        :sort => true, :default => false, :width => 100
      },
      {
        :field => :status_ssi, :label => 'Status',
        :sort => false, :default => true, :width => 100
      },
      {
        :field => :accessioned_dttsim, :label => 'Accession. Datetime',
        :proc => lambda { |doc| render_datetime(doc[:accessioned_dttsim])},
        :sort => true, :default => false, :width => 100
      },
      {
        :field => :published_dttsim, :label => 'Pub. Date',
        :proc => lambda { |doc| render_datetime(doc[:published_dttsim])},
        :sort => true, :default => true, :width => 100
      },
      {
        :field => :workflow_status_ssim, :label => 'Errors',
        :proc => lambda { |doc| doc[:workflow_status_ssim].first.split('|')[2] },
        :sort => true, :default => false, :width => 100
      },
      {
        :field => :file_count, :label => 'Files',
        :proc => lambda { |doc| doc[:content_file_count_itsi] },
        :solr_fields => %w(content_file_count_itsi),
        :sort => false, :default => true, :width => 50
      },
      {
        :field => :shelved_file_count, :label => 'Shelved Files',
        :proc => lambda {|doc| doc[:shelved_content_file_count_itsi] },
        :solr_fields => %w(shelved_content_file_count_itsi),
        :sort => false, :default => true, :width => 50
      },
      {
        :field => :resource_count, :label => 'Resources',
        :proc => lambda {|doc| doc[:resource_count_itsi] },
        :solr_fields => %w(resource_count_itsi),
        :sort => false, :default => true, :width => 50
      },
      {
        :field => :preserved_size, :label => 'Preservation Size',
        :proc => lambda { |doc| doc.preservation_size },
        :solr_fields => [SolrDocument::FIELD_PRESERVATION_SIZE],
        :sort => false, :default => true, :width => 50
      }
    ]

    # common method since search results and reports all do the same configuration
    add_common_date_facet_fields_to_config! config

    # common helper method since search results and reports share most of this config
    BlacklightConfigHelper.add_common_default_solr_params_to_config! config
    config.default_solr_params[:rows] = 100
    config.default_solr_params[:fl] = config.report_fields.collect { |f| f[:solr_fields] || f[:field] }.flatten.uniq.join(',')

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

  # @param [Array<String>] fields
  def initialize(params = {}, fields = nil, current_user: NullUser.new)
    @current_user = current_user
    if fields.nil?
      @fields = self.class.blacklight_config.report_fields
    else
      @fields = self.class.blacklight_config.report_fields.select { |f| fields.include?(f[:field].to_s) }
      @fields.sort! { |a, b| fields.index(a[:field]) <=> fields.index(b[:field]) }
    end
    @params = params
    @params[:page] ||= 1

    (@response, @document_list) = search_results(params, search_params_logic)
    @num_found = @response['response']['numFound'].to_i
  end

  def pids(params)
    @params[:page] = 1
    params[:per_page] = 100
    (@response, @document_list) = search_results(params, search_params_logic)
    toret = []
    while @document_list.length > 0
      report_data.each do |rec|
        if params[:source_id]
          toret << rec[:druid].to_s + "\t" + rec[:source_id_ssim].to_s
        elsif params[:tags]
          tags = ''
          unless rec[:tag_ssim].nil?
            rec[:tag_ssim].split(';').each do |tag|
              tags += "\t" + tag.to_s
            end
          end
          toret << rec[:druid] + tags
        else
          toret << rec[:druid]
        end
      end
      @params[:page] += 1
      (@response, @document_list) = search_results(params, search_params_logic)
    end

    toret
  end

  def report_data
    docs_to_records(@document_list)
  end

  protected

  # @param [Array<SolrDocument>] docs
  # @param [Array<Hash>] fields
  # @return [Array<Hash>]
  def docs_to_records(docs, fields = blacklight_config.report_fields)
    result = []
    docs.each_with_index do |doc, index|
      row = Hash[fields.collect do |spec|
        val = spec.key?(:proc) ? spec[:proc].call(doc) : doc[spec[:field]] rescue nil
        val = val.join('; ') if val.is_a?(Array)
        [spec[:field], val]
      end]
      row['id'] = index + 1
      result << row
    end
    result
  end
end
