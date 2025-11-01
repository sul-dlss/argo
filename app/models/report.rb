# frozen_string_literal: true

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
  ROWS_PER_PAGE_CSV = 10_000

  FREQUENTLY_USED_CATEGORY = 'Frequently used'
  CITATION_CATEGORY = 'Citation'
  HISTORY_CATEGORY = 'History'
  IDENTIFIERS_CATEGORY = 'Identifiers'
  CONTENT_CATEGORY = 'Content'

  REPORT_FIELDS = [
    {
      field: SolrDocument::FIELD_BARE_DRUID, label: 'Druid',
      sort: true, default: true, width: 100, formatter: 'linkToArgo',
      category: FREQUENTLY_USED_CATEGORY
    },
    {
      field: SolrDocument::FIELD_PURL, label: 'Purl',
      sort: false, default: true, width: 100, formatter: 'linkToPurl',
      category: FREQUENTLY_USED_CATEGORY
    },
    {
      field: SolrDocument::FIELD_TITLE, label: 'Title',
      sort: false, default: true, width: 100,
      category: FREQUENTLY_USED_CATEGORY
    },
    {
      field: 'source_id_ssi', label: 'Source ID',
      sort: false, default: true, width: 100,
      category: FREQUENTLY_USED_CATEGORY
    },
    {
      field: SolrDocument::FIELD_COLLECTION_TITLE, label: 'Collection',
      sort: false, default: true, width: 100,
      category: FREQUENTLY_USED_CATEGORY
    },
    {
      field: 'project_tag_ssim', label: 'Project',
      sort: true, default: true, width: 100,
      category: FREQUENTLY_USED_CATEGORY
    },
    {
      field: 'tag_ssim', label: 'Tags',
      sort: true, default: true, width: 100,
      category: FREQUENTLY_USED_CATEGORY
    },
    {
      field: SolrDocument::FIELD_PROCESSING_STATUS, label: 'Status',
      sort: false, default: true, width: 100,
      category: FREQUENTLY_USED_CATEGORY
    },
    {
      field: SolrDocument::FIELD_RELEASED_TO, label: 'Released to',
      sort: false, default: true, width: 100,
      category: FREQUENTLY_USED_CATEGORY
    },
    {
      field: SolrDocument::FIELD_OBJECT_TYPE, label: 'Object type',
      sort: true, default: true, width: 100,
      category: FREQUENTLY_USED_CATEGORY
    },
    {
      field: SolrDocument::FIELD_CONTENT_TYPE, label: 'Content type',
      sort: true, default: true, width: 100,
      category: FREQUENTLY_USED_CATEGORY
    },
    {
      field: SolrDocument::FIELD_APO_TITLE, label: 'Admin policy',
      sort: false, default: true, width: 100,
      category: FREQUENTLY_USED_CATEGORY
    },
    {
      field: SolrDocument::FIELD_ACCESS_RIGHTS, label: 'Access rights',
      sort: false, default: true, width: 100,
      category: FREQUENTLY_USED_CATEGORY
    },
    {
      field: SolrDocument::FIELD_AUTHOR, label: 'Author',
      sort: false, default: false, width: 100,
      category: CITATION_CATEGORY
    },
    {
      field: SolrDocument::FIELD_PLACE, label: 'Place of publication',
      sort: false, default: false, width: 100,
      category: CITATION_CATEGORY
    },
    {
      field: SolrDocument::FIELD_PUBLISHER, label: 'Publisher',
      sort: false, default: false, width: 100,
      category: CITATION_CATEGORY
    },
    {
      field: SolrDocument::FIELD_MODS_CREATED_DATE, label: 'Created date',
      sort: false, default: false, width: 100,
      category: CITATION_CATEGORY
    },
    {
      field: SolrDocument::FIELD_FORMATTED_REGISTERED_EARLIEST, label: 'Registered date',
      sort: true, default: false, width: 100,
      category: HISTORY_CATEGORY
    },
    {
      field: SolrDocument::FIELD_FORMATTED_EARLIEST_ACCESSIONED_DATE, label: 'Accessioned date',
      sort: true, default: false, width: 100,
      category: HISTORY_CATEGORY
    },
    {
      field: SolrDocument::FIELD_FORMATTED_PUBLISHED_EARLIEST_DATE, label: 'Published date',
      sort: true, default: false, width: 100,
      category: HISTORY_CATEGORY
    },
    {
      field: SolrDocument::FIELD_FORMATTED_EMBARGO_RELEASE_DATE, label: 'Embargo release date',
      sort: false, default: false, width: 100,
      category: HISTORY_CATEGORY
    },
    {
      field: 'registered_by_tag_ssim', label: 'Registered by',
      sort: true, default: false, width: 100,
      category: HISTORY_CATEGORY
    },
    {
      field: SolrDocument::FIELD_CURRENT_VERSION, label: 'Version',
      sort: false, default: false, width: 100,
      category: HISTORY_CATEGORY
    },
    {
      field: 'ticket_tag_ssim', label: 'Tickets',
      sort: true, default: false, width: 100,
      category: HISTORY_CATEGORY
    },
    {
      field: SolrDocument::FIELD_WORKFLOW_ERRORS, label: 'Errors',
      sort: false, default: false, width: 100,
      category: HISTORY_CATEGORY
    },
    {
      field: CatalogRecordId.index_field, label: CatalogRecordId.label,
      sort: true, default: false, width: 100,
      category: IDENTIFIERS_CATEGORY
    },
    {
      field: SolrDocument::FIELD_BARCODE_ID, label: 'Barcode',
      sort: true, default: false, width: 100,
      category: IDENTIFIERS_CATEGORY
    },
    {
      field: SolrDocument::FIELD_BARE_APO_ID, label: 'Admin policy ID',
      sort: false, default: false, width: 100,
      category: IDENTIFIERS_CATEGORY
    },
    {
      field: SolrDocument::FIELD_BARE_COLLECTION_ID, label: 'Collection ID',
      sort: false, default: false, width: 100,
      category: IDENTIFIERS_CATEGORY
    },
    {
      field: SolrDocument::FIELD_DISSERTATION_ID, label: 'Dissertation ID',
      sort: false, default: false, width: 50,
      category: IDENTIFIERS_CATEGORY
    },
    {
      field: SolrDocument::FIELD_DOI, label: 'DOI',
      sort: false, default: false, width: 50,
      category: IDENTIFIERS_CATEGORY
    },
    {
      field: 'content_file_count_itsi', label: 'Files',
      sort: false, default: false, width: 50,
      category: CONTENT_CATEGORY
    },
    {
      field: 'shelved_content_file_count_itsi', label: 'Shelved files',
      sort: false, default: false, width: 50,
      category: CONTENT_CATEGORY
    },
    {
      field: 'resource_count_itsi', label: 'Resources',
      sort: false, default: false, width: 50,
      category: CONTENT_CATEGORY
    },
    {
      field: SolrDocument::FIELD_CONSTITUENTS_COUNT, label: 'Constituents',
      sort: true, default: false, width: 100,
      category: CONTENT_CATEGORY
    },
    {
      field: SolrDocument::FIELD_HUMAN_PRESERVED_SIZE, label: 'Preservation size',
      sort: false, default: false, width: 50,
      category: CONTENT_CATEGORY
    },
    {
      field: SolrDocument::FIELD_PRESERVATION_SIZE, label: 'Preservation size (bytes)',
      sort: false, default: false, width: 50,
      category: CONTENT_CATEGORY
    }
  ].freeze

  REPORT_FIELDS_BY_CATEGORY = REPORT_FIELDS.group_by { |f| f[:category] }.freeze

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

    config.max_per_page = ROWS_PER_PAGE_CSV # Must be >= max number of rows want returned.
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
                    REPORT_FIELDS.find { |field_entry| field_entry[:field] == field_name }
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
          druids << ("#{rec[SolrDocument::FIELD_BARE_DRUID]}\t#{rec[SolrDocument::FIELD_SOURCE_ID]}") # rubocop:disable Style/RedundantParentheses
        elsif opts[:tags].present?
          tags = ''
          rec[SolrDocument::FIELD_TAGS]&.split(';')&.each do |tag|
            tags += "\t#{tag}"
          end
          druids << (rec[SolrDocument::FIELD_BARE_DRUID] + tags)
        else
          druids << rec[SolrDocument::FIELD_BARE_DRUID]
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

  def stream_csv(stream:)
    # Wow, yet another BL kludge.
    search_service = search_service(params)
    # Get the underlying Faraday connection to use its streaming API
    connection = search_service.repository.connection.connection
    fl = @fields.collect { |f| f[:solr_fields] || f[:field] }.flatten.uniq.join(',')
    # Setting wt=csv tells solr to return CSV data
    data = { wt: :csv, rows: 10_000_000, fl:, 'csv.mv.separator' => ';' }
           .reverse_merge(search_service.search_builder.with(@params)).to_h

    first_chunk = true
    connection.post blacklight_config.solr_path do |req|
      req.headers['Content-Type'] = 'application/x-www-form-urlencoded; charset=UTF-8'
      req.body = RSolr::Uri.params_to_solr data
      req.options.on_data = proc do |chunk|
        if first_chunk
          first_chunk = false
          # Replace the header row (which comes back from solr with field names) and replace with field labels.
          chunk.sub!(/^.*?\n/m, CSV.generate_line(@fields.map { |field| field.fetch(:label) }, force_quotes: true)) # Remove the header row
        end
        stream.write chunk
      end
    end
  ensure
    stream.close
  end

  private

  def search_results(params)
    search_service(params).search_results
  end

  def search_service(params)
    Blacklight::SearchService.new(config: blacklight_config,
                                  user_params: params,
                                  current_user:)
  end

  # @param [Array<SolrDocument>] docs
  # @param [Array<Hash>] fields
  # @return [Array<Hash(Symbol => String)>]
  def docs_to_records(docs, fields = REPORT_FIELDS)
    docs.map do |doc|
      fields.to_h do |spec|
        val = doc[spec[:field].to_s]
        val = val.join(';') if val.is_a?(Array)
        [spec[:field], val.to_s]
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
