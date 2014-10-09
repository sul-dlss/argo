class DorController < ApplicationController
  around_filter :development_only!, :only => :configuration
  before_filter :authorize!
  respond_to :json, :xml
  respond_to :text, :only => [:query_by_id, :reindex, :delete_from_index]
  def index_logger
    @@index_logger ||= Logger.new("#{Rails.root}/log/indexer.log", 10, 3240000)
    @@index_logger.formatter = proc do |severity, datetime, progname, msg|
      date_format_str = Argo::Config.date_format_str
      "[#{request.uuid}] [#{datetime.strftime(date_format_str)}] #{msg}\n"
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
        Dor::SearchService.solr.add(solr_doc, :add_attributes => {:commitWithin => 1000}) unless obj.nil?
        index_logger.info "updated index for #{params[:pid]}"
        render :text => 'Status:ok<br> Solr Document: '+solr_doc.inspect
        #archive_workflows(obj)
      rescue ActiveFedora::ObjectNotFoundError => e
        index_logger.info "failed to update index for #{params[:pid]}, object not found in Fedora"
        render :status=> 500, :text =>'Object doesnt exist in Fedora.'
        return
      rescue StandardError => se
        index_logger.error "failed to update index for #{params[:pid]}, unexpected error, see main app log"
        raise se
      end
    end
    

    def delete_from_index
      Dor::SearchService.solr.delete_by_id(params[:pid])
      Dor::SearchService.solr.commit
      render :text => params[:pid]
    end

    def republish
      obj=Dor::Item.find(params[:pid])
      obj.publish_metadata_remotely
      render :text => 'Republished! You still need to use the normal versioning process to make sure your changes are preserved.'
    end
    private 
    def archive_workflows obj
      obj.workflows.workflows.each do |wf|
        archive=true #are all processes complete
        active=false #are there any processes without version numbers, meaning they arent archived
        wf.processes.each do |proc|
          if not proc.version and not proc.completed? and not proc.status == 'skipped'
            archive=false
          end
          if not proc.version
            active=true
          end
        end
        if archive and active and wf.repository.first == 'dor'
          Dor::WorkflowService.configure  Argo::Config.urls.workflow, :dor_services_url => Argo::Config.urls.dor_services
          logger.info "Archiving #{wf.repository.first} #{wf.workflowId.first} for #{obj.pid}"
          Dor::WorkflowService.archive_workflow wf.repository.first, obj.pid, wf.workflowId.first
        end      
      end
    end
  end
