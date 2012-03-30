class Dor::ObjectsController < ApplicationController
  before_filter :munge_parameters
  
  def index
  end

  def create
    begin
      other_ids = Array(params[:other_id]).collect do |id|
        if id =~ /^symphony:(.+)$/
          "#{$1.length < 14 ? 'catkey' : 'barcode'}:#{$1}"
        else
          id
        end
      end
    
      if params[:label] == ':auto'
        params.delete(:label)
        params.delete('label')
        metadata_id = Dor::MetadataService.resolvable(other_ids).first
        params[:label] = Dor::MetadataService.label_for(metadata_id)
      end
          
      dor_params = {
        :pid                => params[:pid],
        :admin_policy       => params[:admin_policy],
        :content_model      => params[:model],
        :label              => params[:label],
        :object_type        => params[:object_type],
        :other_ids          => help.ids_to_hash(other_ids),
        :parent             => params[:parent],
        :source_id          => help.ids_to_hash(params[:source_id]),
        :tags               => params[:tag],
        :seed_datastream    => params[:seed_datastream],
        :initiate_workflow  => Array(params[:initiate_workflow]) + Array(params[:workflow_id])
      }
    
      dor_params[:tags] << "Registered By : #{webauth.login}"
      Rails.logger.info(dor_params.inspect)
      dor_obj = Dor::RegistrationService.register_object(dor_params)
      pid = dor_obj.pid
      reg_response = dor_params.dup.merge({ :location => help.object_location(pid), :pid => pid })

      respond_to do |format|
        format.json { render :json => reg_response, :location => help.object_location(pid) }
        format.xml  { render :xml  => reg_response, :location => help.object_location(pid) }
        format.text { render :text => pid, :location => help.object_location(pid) }
        format.html { redirect_to help.object_location(pid) }
      end
    rescue Dor::ParameterError => e
      render :text => e.message, :status => 400
    rescue Dor::DuplicateIdError => e
      render :text => e.message, :status => 409, :location => help.object_location(e.pid)
    rescue Exception => e
      raise
    end
  end

  def show
  end

  def edit
  end

  def update
  end

  def destroy
  end

end
