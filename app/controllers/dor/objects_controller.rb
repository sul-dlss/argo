class Dor::ObjectsController < ApplicationController
  include ApplicationHelper # for fedora_base
  before_action :munge_parameters

  def create
    if params[:collection] && params[:collection].length == 0
      params.delete :collection
    end
    response = Dor::RegistrationService.create_from_request(params)
    pid = response[:pid]

    #
    # we need to reindex and *commit* this new object so that source id checks
    # (which read from the index) work in future registrations.
    #
    # TODO: thus note that this create endpoint will have race conditions if the client
    # sends registration requests concurrently -- ideally this registration should be
    # a serialized process
    #
    Dor::IndexingService.reindex_pid_list([pid], true)

    respond_to do |format|
      format.json { render json: response, location: object_location(pid) }
      format.xml  { render xml: response, location: object_location(pid) }
      format.text { render plain: pid, location: object_location(pid) }
      format.html { redirect_to object_location(pid) }
    end
  rescue Dor::ParameterError => e
    render plain: e.message, status: 400
  rescue Dor::DuplicateIdError => e
    render plain: e.message, status: 409, location: object_location(e.pid)
  rescue StandardError => e
    logger.info e.inspect.to_s
    raise
  end

  private

  def munge_parameters
    case request.content_type
    when 'application/xml', 'text/xml'
      merge_params(Hash.from_xml(request.body.read))
    when 'application/json', 'text/json'
      merge_params(JSON.parse(request.body.read))
    end
  end

  def merge_params(hash)
    # convert camelCase parameter names to under_score, and string keys to symbols
    # e.g., 'objectType' to :object_type
    hash.each_pair do |k, v|
      key = k.underscore
      params[key.to_sym] = v
    end
  end

  def object_location(pid)
    fedora_base.merge("objects/#{pid}").to_s
  end
end
