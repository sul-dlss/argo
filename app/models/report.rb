# frozen_string_literal: true

# Runs a query against solr and returns the results.
# Does exactly what blacklight does, paginates the solr requests untill all results
# have been received
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

  copy_blacklight_config_from CatalogController

  configure_blacklight do |config|
    config.report_fields = [
      {
        field: :druid, label: 'Druid',
        proc: lambda { |doc| doc['id'].split(/:/).last },
        sort: true, default: true, width: 100, download_default: true
      },
      {
        field: :purl, label: 'Purl',
        proc: lambda { |doc| File.join(Settings.purl_url, doc['id'].split(/:/).last) },
        solr_fields: %w(id),
        sort: false, default: false, width: 100, download_default: true
      },
      {
        field: :title, label: 'Title',
        proc: lambda { |doc| retrieve_terms(doc)[:title] },
        solr_fields: %w(sw_display_title_tesim obj_label_ssim),
        sort: false, default: false, width: 100, download_default: true
      },
      {
        field: :citation, label: 'Citation',
        proc: lambda { |doc| render_citation(doc) },
        solr_fields: %w(sw_author_tesim sw_display_title_tesim obj_label_ssim originInfo_place_placeTerm_tesim originInfo_publisher_tesim),
        sort: false, default: true, width: 100, download_default: false
      },
      {
        field: :source_id_ssim, label: 'Source Id',
        sort: false, default: true, width: 100, download_default: true
      },
      {
        field: SolrDocument::FIELD_APO_ID, label: 'Admin Policy ID',
        proc: lambda { |doc| doc[SolrDocument::FIELD_APO_ID].first.split(/:/).last },
        sort: false, default: false, width: 100, download_default: false
      },
      {
        field: SolrDocument::FIELD_APO_TITLE, label: 'Admin Policy',
        sort: false, default: true, width: 100, download_default: false
      },
      {
        field: SolrDocument::FIELD_COLLECTION_ID, label: 'Collection ID',
        proc: lambda { |doc| doc[SolrDocument::FIELD_COLLECTION_ID].map { |id| id.split(/:/).last } },
        sort: false, default: false, width: 100, download_default: false
      },
      {
        field: SolrDocument::FIELD_COLLECTION_TITLE, label: 'Collection',
        proc: lambda { |doc| doc[SolrDocument::FIELD_COLLECTION_TITLE].join(',') },
        sort: false, default: false, width: 100, download_default: false
      },
      {
        field: :project_tag_ssim, label: 'Project',
        sort: true, default: false, width: 100, download_default: false
      },
      {
        field: :registered_by_tag_ssim, label: 'Registered By',
        sort: true, default: false, width: 100, download_default: false
      },
      {
        field: :registered_earliest_dttsi, label: 'Registered',
        proc: lambda { |doc| render_datetime(doc[:registered_earliest_dttsi]) },
        sort: true, default: false, width: 100, download_default: false
      },
      {
        field: :tag_ssim, label: 'Tags',
        sort: true, default: false, width: 100, download_default: false
      },
      {
        field: :objectType_ssim, label: 'Object Type',
        sort: true, default: false, width: 100, download_default: false
      },
      {
        field: :content_type_ssim, label: 'Content Type',
        sort: true, default: false, width: 100, download_default: false
      },
      {
        field: SolrDocument::FIELD_CATKEY_ID, label: 'Catkey',
        sort: true, default: false, width: 100, download_default: false
      },
      {
        field: :barcode_id_ssim, label: 'Barcode',
        sort: true, default: false, width: 100, download_default: false
      },
      {
        field: :status_ssi, label: 'Status',
        sort: false, default: true, width: 100, download_default: true
      },
      {
        field: :accessioned_dttsim, label: 'Accession. Datetime',
        proc: lambda { |doc| render_datetime(doc[:accessioned_dttsim]) },
        sort: true, default: false, width: 100, download_default: false
      },
      {
        field: :published_dttsim, label: 'Pub. Date',
        proc: lambda { |doc| render_datetime(doc[:published_dttsim]) },
        sort: true, default: true, width: 100, download_default: false
      },
      {
        field: :workflow_status_ssim, label: 'Errors',
        proc: lambda { |doc| doc[:workflow_status_ssim].first.split('|')[2] },
        sort: true, default: false, width: 100, download_default: false
      },
      {
        field: :file_count, label: 'Files',
        proc: lambda { |doc| doc[:content_file_count_itsi] },
        solr_fields: %w(content_file_count_itsi),
        sort: false, default: true, width: 50, download_default: false
      },
      {
        field: :shelved_file_count, label: 'Shelved Files',
        proc: lambda { |doc| doc[:shelved_content_file_count_itsi] },
        solr_fields: %w(shelved_content_file_count_itsi),
        sort: false, default: true, width: 50, download_default: false
      },
      {
        field: :resource_count, label: 'Resources',
        proc: lambda { |doc| doc[:resource_count_itsi] },
        solr_fields: %w(resource_count_itsi),
        sort: false, default: true, width: 50, download_default: false
      },
      {
        field: :preserved_size, label: 'Preservation Size',
        proc: lambda { |doc| doc.preservation_size },
        solr_fields: [SolrDocument::FIELD_PRESERVATION_SIZE],
        sort: false, default: true, width: 50, download_default: false
      }
    ]

    config.search_builder_class = ReportSearchBuilder # leave off faceting for report queries

    config.default_solr_params[:rows] = 100
    config.default_solr_params[:fl] = config.report_fields.collect { |f| f[:solr_fields] || f[:field] }.flatten.uniq.join(',')

    config.sort_fields.clear
    config.add_sort_field 'id asc', label: 'Druid'

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
      @fields = blacklight_config.report_fields
    else
      @fields = blacklight_config.report_fields.select { |f| fields.include?(f[:field].to_s) }
      @fields.sort! { |a, b| fields.index(a[:field].to_s) <=> fields.index(b[:field].to_s) }
    end
    @params = params
    @params[:page] ||= 1
    (@response, @document_list) = search_results(@params)
    @num_found = @response['response']['numFound'].to_i
  end

  def pids(opts = {})
    params[:page] = 1
    params[:per_page] = 100
    (@response, @document_list) = search_results(params)
    pids = []
    while @document_list.length > 0
      report_data.each do |rec|
        if opts[:source_id].present?
          pids << rec[:druid] + "\t" + rec[:source_id_ssim]
        elsif opts[:tags].present?
          tags = ''
          rec[:tag_ssim]&.split(';')&.each do |tag|
            tags += "\t" + tag
          end
          pids << rec[:druid] + tags
        else
          pids << rec[:druid]
        end
      end
      params[:page] += 1
      (@response, @document_list) = search_results(params)
    end

    pids
  end

  def report_data
    docs_to_records(@document_list)
  end

  protected

  # @param [Array<SolrDocument>] docs
  # @param [Array<Hash>] fields
  # @return [Array<Hash(Symbol => String)>]
  def docs_to_records(docs, fields = blacklight_config.report_fields)
    result = []
    docs.each_with_index do |doc, index|
      row = Hash[fields.collect do |spec|
        val = spec.key?(:proc) ? spec[:proc].call(doc) : doc[spec[:field].to_s] rescue nil
        val = val.join(';') if val.is_a?(Array)
        [spec[:field].to_sym, val.to_s]
      end]
      row[:id] = index + 1
      result << row
    end
    result
  end
end
