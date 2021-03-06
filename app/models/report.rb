# frozen_string_literal: true

# Runs a query against solr and returns the results.
# Does exactly what blacklight does, paginates the solr requests untill all results
# have been received
# rubocop:disable Metrics/ClassLength
class Report
  include Blacklight::Configurable
  include CsvConcern
  include DateFacetConfigurations
  include Blacklight::Searchable

  class << self
    include ValueHelper
  end

  REPORT_FIELDS = [
    {
      field: :druid, label: 'Druid',
      proc: ->(doc) { doc.druid },
      sort: true, default: true, width: 100, download_default: true
    },
    {
      field: :purl, label: 'Purl',
      proc: ->(doc) { File.join(Settings.purl_url, doc.druid) },
      solr_fields: %w[id],
      sort: false, default: false, width: 100, download_default: true
    },
    {
      field: :title, label: 'Title',
      proc: ->(doc) { doc.title },
      solr_fields: [SolrDocument::FIELD_TITLE,
                    SolrDocument::FIELD_LABEL],
      sort: false, default: false, width: 100, download_default: true
    },
    {
      field: :citation, label: 'Citation',
      proc: ->(doc) { CitationPresenter.new(doc).render },
      solr_fields: [SolrDocument::FIELD_AUTHOR,
                    SolrDocument::FIELD_TITLE,
                    SolrDocument::FIELD_LABEL,
                    SolrDocument::FIELD_PLACE,
                    SolrDocument::FIELD_PUBLISHER,
                    SolrDocument::FIELD_CREATED_DATE],
      sort: false, default: true, width: 100, download_default: false
    },
    {
      field: :source_id_ssim, label: 'Source Id',
      sort: false, default: true, width: 100, download_default: true
    },
    {
      field: SolrDocument::FIELD_APO_ID, label: 'Admin Policy ID',
      proc: ->(doc) { doc[SolrDocument::FIELD_APO_ID].first.delete_prefix('druid:') },
      sort: false, default: false, width: 100, download_default: false
    },
    {
      field: SolrDocument::FIELD_APO_TITLE, label: 'Admin Policy',
      sort: false, default: true, width: 100, download_default: false
    },
    {
      field: SolrDocument::FIELD_COLLECTION_ID, label: 'Collection ID',
      proc: ->(doc) { doc[SolrDocument::FIELD_COLLECTION_ID].map { |id| id.delete_prefix('druid:') } },
      sort: false, default: false, width: 100, download_default: false
    },
    {
      field: SolrDocument::FIELD_COLLECTION_TITLE, label: 'Collection',
      proc: ->(doc) { doc[SolrDocument::FIELD_COLLECTION_TITLE].join(',') },
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
      proc: ->(doc) { DatePresenter.render(doc[:registered_earliest_dttsi]) },
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
      proc: ->(doc) { DatePresenter.render(doc[:accessioned_dttsim]) },
      sort: true, default: false, width: 100, download_default: false
    },
    {
      field: :published_dttsim, label: 'Pub. Date',
      proc: ->(doc) { DatePresenter.render(doc[:published_dttsim]) },
      sort: true, default: true, width: 100, download_default: false
    },
    {
      field: :workflow_status_ssim, label: 'Errors',
      proc: ->(doc) { doc[:workflow_status_ssim].first.split('|')[2] },
      sort: true, default: false, width: 100, download_default: false
    },
    {
      field: :file_count, label: 'Files',
      proc: ->(doc) { doc[:content_file_count_itsi] },
      solr_fields: %w[content_file_count_itsi],
      sort: false, default: true, width: 50, download_default: false
    },
    {
      field: :shelved_file_count, label: 'Shelved Files',
      proc: ->(doc) { doc[:shelved_content_file_count_itsi] },
      solr_fields: %w[shelved_content_file_count_itsi],
      sort: false, default: true, width: 50, download_default: false
    },
    {
      field: :resource_count, label: 'Resources',
      proc: ->(doc) { doc[:resource_count_itsi] },
      solr_fields: %w[resource_count_itsi],
      sort: false, default: true, width: 50, download_default: false
    },
    {
      field: :preserved_size, label: 'Preservation Size',
      proc: ->(doc) { doc.preservation_size },
      solr_fields: [SolrDocument::FIELD_PRESERVATION_SIZE],
      sort: false, default: true, width: 50, download_default: false
    },
    {
      field: :dissertation_id, label: 'Dissertation ID',
      proc: ->(doc) { doc[:identifier_ssim].filter { |id| id.include?('dissertationid') }.map { |id| id.split(/:/).last } },
      solr_fields: %w[identifier_ssim],
      sort: false, default: true, width: 50, download_default: false
    }
  ].freeze

  COLUMN_MODEL = REPORT_FIELDS.collect do |spec|
    {
      'name' => spec[:field],
      'jsonmap' => spec[:field],
      'label' => spec[:label],
      'index' => spec[:field],
      'width' => spec[:width],
      'sortable' => spec[:sort],
      'hidden' => (!spec[:default])
    }
  end

  attr_reader :response, :document_list, :num_found, :params, :current_user

  copy_blacklight_config_from CatalogController

  configure_blacklight do |config|
    config.search_builder_class = ReportSearchBuilder # leave off faceting for report queries

    config.default_solr_params[:rows] = 100
    config.default_solr_params[:fl] = REPORT_FIELDS.collect { |f| f[:solr_fields] || f[:field] }.flatten.uniq.join(',')

    config.sort_fields.clear
    config.add_sort_field 'id asc', label: 'Druid'
  end

  # @param [Array<String>] fields
  def initialize(params = {}, fields = nil, current_user: NullUser.new)
    @current_user = current_user
    @fields = if fields.nil?
                REPORT_FIELDS
              else
                REPORT_FIELDS.select { |f| fields.include?(f[:field].to_s) }
                             .sort { |a, b| fields.index(a[:field].to_s) <=> fields.index(b[:field].to_s) }
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
    until @document_list.empty?
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

  private

  delegate :search_results, to: :search_service

  def search_results(params)
    search_service(params).search_results
  end

  # TODO: Refactor to use Blacklight::Searchable instead.  Requires a SearchState rather than params
  def search_service(params)
    search_service_class.new(config: blacklight_config,
                             user_params: params,
                             current_user: current_user)
  end

  # We can remove this when https://github.com/projectblacklight/blacklight/pull/2320 is merged into Blacklight
  def search_service_class
    Blacklight::SearchService
  end

  # @param [Array<SolrDocument>] docs
  # @param [Array<Hash>] fields
  # @return [Array<Hash(Symbol => String)>]
  def docs_to_records(docs, fields = REPORT_FIELDS)
    result = []
    docs.each_with_index do |doc, index|
      row = fields.collect do |spec|
        val =
          begin
            spec.key?(:proc) ? spec[:proc].call(doc) : doc[spec[:field].to_s]
          rescue StandardError
            nil
          end
        val = val.join(';') if val.is_a?(Array)
        [spec[:field].to_sym, val.to_s]
      end.to_h
      row[:id] = index + 1
      result << row
    end
    result
  end
end
# rubocop:enable Metrics/ClassLength
