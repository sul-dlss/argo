class Dor::ObjectsController < ApplicationController
  before_filter :munge_parameters

  def index
  end

  def create
    begin
      if params[:collection] and params[:collection].length ==0
        params.delete :collection
      end
      response = Dor::RegistrationService.create_from_request(params)
      pid = response[:pid]

      respond_to do |format|
        format.json { render :json => response, :location => help.object_location(pid) }
        format.xml  { render :xml  => response, :location => help.object_location(pid) }
        format.text { render :text => pid, :location => help.object_location(pid) }
        format.html { redirect_to help.object_location(pid) }
      end
    rescue Dor::ParameterError => e
      render :text => e.message, :status => 400
    rescue Dor::DuplicateIdError => e
      render :text => e.message, :status => 409, :location => help.object_location(e.pid)
    rescue Exception => e
      logger.info e.inspect.to_s
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
