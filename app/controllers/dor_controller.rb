class DorController < ApplicationController
  around_filter :development_only!, :only => :configuration
  before_filter :authorize!
  respond_to :json, :xml
  respond_to :text, :only => [:query_by_id, :reindex, :delete_from_index]
  def index_logger
    @@index_logger ||= Logger.new("#{Rails.root}/log/indexer.log", 10, 3240000)
    @@index_logger.formatter = proc do |severity, datetime, progname, msg|
      "#{datetime}: #{msg}\n"
    end
    @@index_logger
  end

  def configuration
    result = Dor::Config.to_hash.merge({
      :environment => Rails.env, 
      :webauth => { 
        :authrule => webauth.authrule,
        :logged_in => webauth.logged_in?,
        :login => webauth.login,
        :attributes => webauth.attributes,
        :privgroup => webauth.privgroup
      }
      })
      respond_with(result)
    end

    def query_by_id
      unless params[:id]
        response.status = 400
        return
      end

      result = Dor::SearchService.query_by_id(params[:id]).collect do |pid|
        { :id => pid, :url => url_for(:controller => 'dor/objects', :id => pid) }
      end

      respond_with(result) do |format|
        format.any(:json, :xml) { render request.format.to_sym => result }
        format.text { render :text => result.collect { |v| v[:id] }.join("\n") }
      end
    end

    def label
      respond_with params.merge('label' => Dor::MetadataService.label_for(params[:source_id]))
    end

    def reindex
      begin
      obj = Dor.load_instance params[:pid]
      solr_doc = obj.to_solr
      index_logger.info "updated index for #{params[:pid]}"
      Dor::SearchService.solr.add(solr_doc, :add_attributes => {:commitWithin => 1000}) unless obj.nil?
      index_logger.info "updated index for #{params[:pid]}"
      render :text => 'Status:ok<br> Solr Document: '+solr_doc.inspect
      rescue ActiveFedora::ObjectNotFoundError => e
        render :status=> 500, :text =>'Object doesnt exist in Fedora.'
        return
      end
    end

    def delete_from_index
      Dor::SearchService.solr.delete_by_id(params[:pid])
      Dor::SearchService.solr.commit
      render :text => params[:pid]
    end

    def index_exceptions
      @exceptions = IndexingException.order(:created_at).reverse_order.page(params[:page]).per(50)
    end

    def republish
      obj=Dor::Item.find(params[:pid])
      obj.publish_metadata
      render :text => 'Republished! You still need to use the normal versioning process to make sure your changes are preserved.'
    end

    def archive_workflows
      obj=Dor::Item.find(params[:pid])
      wf=obj.workflows.get_workflow('accessionWF','dor')
      wf.processes.each do |proc|
        if proc.status != 'completed'
          raise 'Unable to archive accessionWF, ' + proc.name + 'is not in completed status, it is in ' + proc.status
        end
      end
      Dor::WorkflowService.archive_workflow 'dor', pid, wf.name
    end
  end
