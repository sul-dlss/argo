require 'csv'

class Discovery
  include BlacklightSolrExtensions
  include Blacklight::Configurable
  include Blacklight::SolrHelper
  include CsvConcern

  attr_reader :response, :document_list, :num_found, :params

  configure_blacklight do |config|

    config.discovery_fields = [
      {
        :label => 'Druid', :field => 'druid',
        :proc => lambda { |doc| doc['id'].split(/:/).last },
        :sort => true, :default => true, :width => 100
      },
      {
        :label => 'Druid', :field => 'id',
        :sort => true, :default => false, :width => 100
      },
      {
        :label => 'Display Title',
        :field => 'title_ssim',
        :sort => true, :default => true, :width => 200
      },
      {
        :label => 'Format',
        :field => 'sw_format_tesim',
        :default => true, :width => 200
      },
      {
        :label => 'Sort Title',
        :field => 'title_sort_ssi',
        :default => false, :width => 200
      },
      {
        :label => 'Topic Search',
        :field => 'topic_tesim',
        :default => false, :width => 200
      },
      {
        :label => 'Subject All',
        :field => 'subject_topic_tesim',
        :default => false, :width => 200
      },
      {
        :label => 'Topic Facet',
        :field => 'topic_tesim',
        :default => false, :width => 200
      },
      {
        :label => 'Geographic Facet',
        :field => 'sw_subject_geographic_ssim',
        :default => false, :width => 200
      },
      {
        :label => 'Era Facet',
        :field => 'sw_subject_temporal_ssim',
        :default => false, :width => 200
      },
      {
        :label => 'Language Facet',
        :field => 'sw_language_tesim',
        :default => true, :width => 200
      },
      {
        :label => 'Pub Date Sort',
        :field => 'sw_pub_date_sort_ssi',
        :default => false, :width => 200
      },
      {
        :label => 'Pub Date Group Facet',
        :field => 'sw_pub_date_facet_ssi',
        :default => false, :width => 200
      },

      {
        :label => 'Pub Year Facet',
        :field => 'sw_pub_date_sort_ssi',
        :default => true, :width => 200
      },
      {
        :label => 'Pub Date Display',
        :field => 'sw_pub_date_facet_ssi',
        :default => true, :width => 200
      }
    ]

    # common helper method since search results and reports all do the same configuration
    BlacklightConfigHelper.add_common_date_facet_fields_to_config! config

    # common helper method since search results and reports share most of this config
    BlacklightConfigHelper.add_common_default_solr_params_to_config! config
    config.default_solr_params[:rows] = 100
    config.default_solr_params[:fl] = config.discovery_fields.map { |f| f[:solr_fields] || f[:field] }.flatten.uniq.join(',')

    config.add_sort_field 'id asc', :label => 'Druid'

    config.column_model = config.discovery_fields.map { |spec|
      {
        'name'     => spec[:field],
        'jsonmap'  => spec[:field],
        'label'    => spec[:label],
        'index'    => spec[:field],
        'width'    => spec[:width],
        'sortable' => spec[:sort],
        'hidden'   => (!spec[:default])
      }
    }
  end

  def initialize(params = {}, fields = nil)
    if fields.nil?
      @fields = self.class.blacklight_config.discovery_fields
    else
      @fields = self.class.blacklight_config.discovery_fields.select { |f| fields.nil? || fields.include?(f[:field]) }
      @fields.sort! { |a, b| fields.index(a[:field]) <=> fields.index(b[:field]) }
    end
    @params = params
    @params[:page] ||= 1

    (@response, @document_list) = get_search_results
    @num_found = @response['response']['numFound'].to_i
  end

  def pids(params)
    toret = []
    while @document_list.length > 0
      report_data.each do|rec|
        if params[:source_id]
          toret << rec['druid'].to_s + "\t" + rec['source_id_ssim'].to_s
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

  protected

  def docs_to_records(docs, fields = blacklight_config.discovery_fields)
    docs.each_with_index.map do |doc, index|
      row = Hash[fields.map do |spec|
        val = spec.key?(:proc) ? spec[:proc].call(doc) : doc[spec[:field]] rescue nil
        val = val.join('; ') if val.is_a?(Array)
        [spec[:field], val]
      end]
      row['id'] = index + 1
      row
    end
  end
end
