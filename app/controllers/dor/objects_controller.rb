class Dor::ObjectsController < ApplicationController
  before_filter :munge_parameters
  
  def index
  end

  def create
    if params[:label] == ':auto'
      params.delete(:label)
      params.delete('label')
      metadata_id = Dor::MetadataService.resolvable(Array(params[:other_id])).first
      params[:label] = Dor::MetadataService.label_for(metadata_id)
    end
  
    dor_params = {
      :pid                => params[:pid],
      :admin_policy       => params[:admin_policy],
      :content_model      => params[:model],
      :label              => params[:label],
      :object_type        => params[:object_type],
      :other_ids          => help.ids_to_hash(params[:other_id]),
      :parent             => params[:parent],
      :source_id          => help.ids_to_hash(params[:source_id]),
      :tags               => params[:tag]
    }
    
    begin
      dor_response = Dor::RegistrationService.register_object(dor_params)
      reg_response = dor_params.dup.merge({ :location => help.object_location(dor_response[:pid]), :pid => dor_response[:pid] })
      if params[:seed_datastream]
        dor_obj = help.class_for(params[:object_type]).load_instance(dor_response[:pid])
        Array(params[:seed_datastream]).each do |datastream_name|
          dor_obj.build_datastream(datastream_name)
        end
      end
      
      respond_to do |format|
        format.json { render :json => reg_response, :location => help.object_location(dor_response[:pid]) }
        format.xml  { render :xml  => reg_response, :location => help.object_location(dor_response[:pid]) }
        format.text { render :text => dor_respond[:pid], :location => help.object_location(dor_response[:pid]) }
        format.html { redirect_to help.object_location(dor_response[:pid]) }
      end
    rescue Dor::ParameterError => e
      render :text => e.message, :status => 400
    rescue Dor::DuplicateIdError => e
      render :text => e.message, :status => 409, :location => help.object_location(e.pid)
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
