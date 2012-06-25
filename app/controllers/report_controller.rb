# -*- encoding : utf-8 -*-
require 'blacklight/catalog'

class ReportController < CatalogController

  include BlacklightSolrExtensions
  include Blacklight::Catalog
  helper ArgoHelper
  copy_blacklight_config_from CatalogController

  class << self
    include DorObjectHelper
    include ValueHelper
  end
  
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
        :sort => false, :default => false, :width => 100 
      },
      { 
        :field => 'title', :label => "Title", 
        :proc => lambda { |doc| retrieve_terms(doc)[:title] }, 
        :sort => false, :default => false, :width => 100 
      },
      { 
        :field => 'citation', :label => "Citation", 
        :proc => lambda { |doc| render_citation(doc) }, 
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
        :proc => lambda { |doc| label_for_druid(doc['is_governed_by_s']) rescue nil }, 
        :sort => false, :default => true, :width => 100 
      },
      { 
        :field => 'collection_druid', :label => 'Collection ID', 
        :proc => lambda { |doc| doc['is_member_of_collection_s'].first.split(/:/).last rescue nil }, 
        :sort => false, :default => false, :width => 100
      },
      { 
        :field => 'collection', :label => "Collection", 
        :proc => lambda { |doc| label_for_druid(doc['is_member_of_collection_s']) }, 
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
        :proc => lambda { |doc| doc['lifecycle_facet'].last rescue nil },
        :sort => false, :default => true, :width => 100 
      },
      { 
        :field => 'published_dt', :label => "Pub. Date", 
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
        :sort => true, :default => false, :width => 100 
      }
    ]
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
  
  def default_html_head
    super
    stylesheet_links << ['ui.jqgrid']
    javascript_includes << ['report']
  end
  
  def rsolr_request_error(exception)
    raise exception
  end
  
  def data
    params[:sort] = "#{params.delete(:sidx)} #{params.delete(:sord)}" if params[:sidx].present?
    rows_per_page = params.delete(:rows).to_i
    params[:per_page] = rows_per_page * [params.delete(:npage).to_i,1].max
    delete_or_assign_search_session_params
    (@response, @document_list) = get_search_results
    num_found = @response['response']['numFound'].to_i
    result = []
    @document_list.each_with_index do |doc,index|
      row = Hash[blacklight_config.report_fields.collect do |spec|
        val = spec.has_key?(:proc) ? spec[:proc].call(doc) : doc[spec[:field]]
        val = val.join('; ') if val.is_a?(Array)
        [spec[:field],val]
      end]
      row['id'] = index + 1
      result << row
    end
    
    respond_to do |format|
      format.json { 
        render :json => {
          :page => params[:page].to_i,
          :records => num_found,
          :total => (num_found / rows_per_page.to_f).ceil,
          :rows => result
        }
      }
      format.xml  { render :xml  => result }
#      format.csv  { render :csv  => }
    end
  end
  
  def workflow_grid
    delete_or_assign_search_session_params
    (@response, @document_list) = get_search_results
    if request.xhr?
      render :partial => 'workflow_grid'
    else
      render
    end
  end
  
end
