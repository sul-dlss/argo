# frozen_string_literal: true

require 'csv'

# Runs a query against solr and returns the results.
# Does exactly what blacklight does, paginates the solr requests until all results
# have been received
# rubocop:disable Metrics/ClassLength
class Report
  include Blacklight::Configurable
  include DateFacetConfigurations
  include Blacklight::Searchable

  class << self
    include ValueHelper
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::NumberHelper
  end

  COLUMN_SELECTOR_COLUMN_SIZE = 3 # Helps display report columns in neatly lined up columns.
  ROWS_PER_PAGE = 100

  REPORT_FIELDS = [
    {
      field: :druid, label: 'Druid',
      proc: ->(doc) { doc.druid },
      sort: true, default: true, width: 100, formatter: 'linkToArgo'
    },
    {
      field: :purl, label: 'Purl',
      proc: ->(doc) { "#{Settings.purl_url}/#{doc.druid}" },
      solr_fields: %w[id],
      sort: false, default: false, width: 100, formatter: 'linkToPurl'
    },
    {
      field: SolrDocument::FIELD_RELEASED_TO, label: 'Released To',
      proc: ->(doc) { doc.released_to.presence&.to_sentence || 'Not released' },
      sort: false, default: false, width: 100
    },
    {
      field: :title, label: 'Title',
      proc: ->(doc) { doc.title },
      solr_fields: [SolrDocument::FIELD_TITLE,
                    SolrDocument::FIELD_LABEL],
      sort: false, default: true, width: 100
    },
    {
      field: :citation, label: 'Citation',
      proc: ->(doc) { CitationPresenter.new(doc).render },
      solr_fields: [SolrDocument::FIELD_AUTHOR,
                    SolrDocument::FIELD_TITLE,
                    SolrDocument::FIELD_LABEL,
                    SolrDocument::FIELD_PLACE,
                    SolrDocument::FIELD_PUBLISHER,
                    SolrDocument::FIELD_MODS_CREATED_DATE],
      sort: false, default: false, width: 100
    },
    {
      field: :source_id_ssim, label: 'Source ID',
      sort: false, default: true, width: 100
    },
    {
      field: SolrDocument::FIELD_APO_ID, label: 'Admin Policy ID',
      proc: ->(doc) { Druid.new(doc[SolrDocument::FIELD_APO_ID].first).without_namespace },
      sort: false, default: false, width: 100
    },
    {
      field: SolrDocument::FIELD_APO_TITLE, label: 'Admin Policy',
      sort: false, default: true, width: 100
    },
    {
      field: SolrDocument::FIELD_COLLECTION_ID, label: 'Collection ID',
      proc: ->(doc) { doc[SolrDocument::FIELD_COLLECTION_ID].map { |id| Druid.new(id).without_namespace } },
      sort: false, default: false, width: 100
    },
    {
      field: SolrDocument::FIELD_COLLECTION_TITLE, label: 'Collection',
      proc: ->(doc) { doc[SolrDocument::FIELD_COLLECTION_TITLE].join(',') },
      sort: false, default: true, width: 100
    },
    {
      field: :project_tag_ssim, label: 'Project',
      sort: true, default: false, width: 100
    },
    {
      field: :registered_by_tag_ssim, label: 'Registered By',
      sort: true, default: false, width: 100
    },
    {
      field: :registered_earliest_dttsi, label: 'Registered',
      proc: ->(doc) { DatePresenter.render(doc[:registered_earliest_dttsi]) },
      sort: true, default: false, width: 100
    },
    {
      field: :tag_ssim, label: 'Tags',
      sort: true, default: false, width: 100
    },
    {
      field: :objectType_ssim, label: 'Object Type',
      sort: true, default: false, width: 100
    },
    {
      field: :content_type_ssim, label: 'Content Type',
      sort: true, default: false, width: 100
    },
    {
      field: SolrDocument::FIELD_CONSTITUENTS.to_sym, label: 'Constituents',
      proc: ->(doc) { doc[SolrDocument::FIELD_CONSTITUENTS]&.size || 'Not a virtual object' },
      sort: true, default: false, width: 100
    },
    {
      field: CatalogRecordId.index_field, label: CatalogRecordId.label,
      sort: true, default: false, width: 100
    },
    {
      field: :barcode_id_ssim, label: 'Barcode',
      sort: true, default: false, width: 100
    },
    {
      field: SolrDocument::FIELD_CURRENT_VERSION.to_sym, label: 'Version',
      sort: false, default: true, width: 100
    },
    {
      field: :processing_status_text_ssi, label: 'Status',
      sort: false, default: true, width: 100
    },
    {
      field: SolrDocument::FIELD_ACCESS_RIGHTS.to_sym, label: 'Access Rights',
      sort: false, default: true, width: 100
    },
    {
      field: SolrDocument::FIELD_EMBARGO_RELEASE_DATE, label: 'Embargo Release Date',
      proc: ->(doc) { doc.embargo_release_date || 'Not embargoed' },
      sort: false, default: false, width: 100
    },
    {
      field: :accessioned_earliest_dttsi, label: 'Accession. Datetime',
      proc: ->(doc) { DatePresenter.render(doc[:accessioned_earliest_dttsi]) },
      sort: true, default: false, width: 100
    },
    {
      field: :published_earliest_dttsi, label: 'Pub. Date',
      proc: ->(doc) { DatePresenter.render(doc[:published_earliest_dttsi]) },
      sort: true, default: false, width: 100
    },
    {
      field: SolrDocument::FIELD_WORKFLOW_ERRORS.to_sym, label: 'Errors',
      proc: ->(doc) { doc[SolrDocument::FIELD_WORKFLOW_ERRORS] },
      sort: false, default: false, width: 100
    },
    {
      field: :file_count, label: 'Files',
      proc: ->(doc) { doc[:content_file_count_itsi] },
      solr_fields: %w[content_file_count_itsi],
      sort: false, default: true, width: 50
    },
    {
      field: :shelved_file_count, label: 'Shelved Files',
      proc: ->(doc) { doc[:shelved_content_file_count_itsi] },
      solr_fields: %w[shelved_content_file_count_itsi],
      sort: false, default: true, width: 50
    },
    {
      field: :resource_count, label: 'Resources',
      proc: ->(doc) { doc[:resource_count_itsi] },
      solr_fields: %w[resource_count_itsi],
      sort: false, default: false, width: 50
    },
    {
      field: :preserved_size_human, label: 'Preservation Size',
      proc: ->(doc) { number_to_human_size(doc.preservation_size) },
      solr_fields: [SolrDocument::FIELD_PRESERVATION_SIZE],
      sort: false, default: true, width: 50
    },
    {
      field: :preserved_size, label: 'Preservation Size (bytes)',
      proc: ->(doc) { number_with_precision(doc.preservation_size, precision: 0) },
      solr_fields: [SolrDocument::FIELD_PRESERVATION_SIZE],
      sort: false, default: true, width: 50
    },
    {
      field: :dissertation_id, label: 'Dissertation ID',
      proc: lambda { |doc|
              doc[:identifier_ssim].filter do |id|
                id.include?('dissertationid')
              end.map { |id| id.split(':').last }
            },
      solr_fields: %w[identifier_ssim],
      sort: false, default: false, width: 50
    }
  ].freeze

  COLUMN_MODEL = REPORT_FIELDS.map do |spec|
    {
      'field' => spec[:field],
      'title' => spec[:label],
      'visible' => spec[:default],
      'minWidth' => spec[:width],
      'formatter' => spec[:formatter],
      # Disable sorting due to behavior that will confuse users, namely the
      # likelihood of a user attempting to sort a column before the full report
      # data set has loaded, namely that we are loading data sets progressively
      # as users scroll down the reports view to keep performance satisfactory.
      # Sorting a partial data set only to scroll to the bottom and have more
      # rows load will look strange, and give users false confidence that they
      # are looking at the complete data set.
      'headerSort' => false # spec[:sort]
    }
  end

  attr_reader :response, :document_list, :num_found, :params, :current_user

  copy_blacklight_config_from CatalogController

  configure_blacklight do |config|
    config.search_builder_class = ReportSearchBuilder # leave off faceting for report queries

    config.default_solr_params[:rows] = ROWS_PER_PAGE
    config.default_solr_params[:fl] = REPORT_FIELDS.collect { |f| f[:solr_fields] || f[:field] }.flatten.uniq.join(',')

    config.sort_fields.clear
    config.add_sort_field 'id asc', label: 'Druid'
  end

  # @param [Array<String>] fields
  def initialize(params = {}, current_user: NullUser.new)
    @current_user = current_user
    @fields = if params[:fields].present?
                params
                  .delete(:fields)
                  .split(/\s*,\s*/)
                  .map do |field_name|
                    REPORT_FIELDS.find { |field_entry| field_entry[:field] == field_name.to_sym }
                  end
              else
                REPORT_FIELDS
              end
    @params = params
    (@response,) = search_results(@params)
    @num_found = @response['response']['numFound'].to_i
  end

  def druids(opts = {})
    params[:page] = 1
    params[:per_page] = ROWS_PER_PAGE
    (@response,) = search_results(params)
    druids = []
    until @response.documents.empty?
      report_data.each do |rec|
        if opts[:source_id].present?
          druids << ("#{rec[:druid]}\t#{rec[:source_id_ssim]}")
        elsif opts[:tags].present?
          tags = ''
          rec[:tag_ssim]&.split(';')&.each do |tag|
            tags += "\t#{tag}"
          end
          druids << (rec[:druid] + tags)
        else
          druids << rec[:druid]
        end
      end
      params[:page] += 1
      (@response,) = search_results(params)
    end

    druids
  end

  def report_data
    docs_to_records(@response.documents)
  end

  ##
  # Converts the `report_data` into CSV data
  #
  # @return [Enumerator] data in CSV format
  def to_csv
    @params[:page] = 1
    @params[:per_page] = ROWS_PER_PAGE
    Enumerator.new do |yielder|
      yielder << CSV.generate_line(@fields.map { |field| field.fetch(:label) }, force_quotes: true) # header row
      until @response.documents.empty?
        report_data.each do |record|
          yielder << CSV.generate_line(@fields.map { |field| record[field.fetch(:field)].to_s }, force_quotes: true)
        end
        @params[:page] += 1
        (@response,) = search_results(@params)
      end
    end
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
                             current_user:)
  end

  # We can remove this when https://github.com/projectblacklight/blacklight/pull/2320 is merged into Blacklight
  def search_service_class
    Blacklight::SearchService
  end

  # @param [Array<SolrDocument>] docs
  # @param [Array<Hash>] fields
  # @return [Array<Hash(Symbol => String)>]
  def docs_to_records(docs, fields = REPORT_FIELDS)
    docs.map do |doc|
      fields.to_h do |spec|
        val =
          begin
            spec.key?(:proc) ? spec[:proc].call(doc) : doc[spec[:field].to_s]
          rescue StandardError
            nil
          end
        val = val.join(';') if val.is_a?(Array)
        [spec[:field].to_sym, val.to_s]
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
