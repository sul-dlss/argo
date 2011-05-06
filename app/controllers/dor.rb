RubyDorServices.controllers :dor do

  before do
    case request.content_type
    when 'application/xml','text/xml'
      merge_params(Hash.from_xml(request.body.read))
    when 'application/json','text/json'
      merge_params(JSON.parse(request.body.read))
    end
  end
  
  get :config, :running_in => /development/ do
    content_type :json
    Dor::Config.to_hash.merge({:environment, options.environment}).to_json
  end

  get :describe, :provides => [:html, :xml, :json] do
    resp = {
      :version => VERSION,
      :urls => [
        { :method => 'POST', :endpoint => url('/objects'), :params => { :required => [ 'objectType', 'label' ], :optional => [ 'adminPolicy', 'model', 'objectAdminClass', 'otherId', 'sourceId', 'tag', 'parent' ] } },
        { :method => 'GET', :endpoint => url('/query_by_id'), :params => { :required =>  [ 'id' ] } }
      ]
    }
    case content_type
    when :html  then '<pre>'+resp.inspect+'</pre>'
    when :xml   then render 'dor/describe', :locals => { :data => resp }
    when :json  then resp.to_json
    end
  end

  post :objects, :provides => [:json,:xml,:txt,:text,:html] do
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
      :other_ids          => ids_to_hash(params[:other_id]),
      :parent             => params[:parent],
      :source_id          => ids_to_hash(params[:source_id]),
      :tags               => params[:tag]
    }
    
    begin
      dor_response = Dor::RegistrationService.register_object(dor_params)
      reg_response = dor_params.dup.merge({ :location => object_location(dor_response[:pid]), :pid => dor_response[:pid] })
      if params[:seed_datastream]
        dor_obj = Dor::Base.load_instance(dor_response[:pid])
        Array(params[:seed_datastream]).each do |datastream_name|
          dor_obj.build_datastream(datastream_name)
        end
      end
      headers "Location" => object_location(dor_response[:pid])
      status dor_response[:response].code
      case content_type
      when :txt,
           :text  then body dor_response[:pid]
      when :xml   then reg_response.to_xml
      when :json  then reg_response.to_json
      when :html  then redirect object_location(dor_response[:pid])
      end
    rescue Dor::ParameterError => e
      halt 400, e.message
    rescue Dor::DuplicateIdError => e
      headers "Location" => object_location(e.pid)
      halt 409, e.message
    end
  end

  get :query_by_id, :provides => [:txt,:text,:xml,:json] do
    halt 400 unless params[:id]
    result = Dor::SearchService.query_by_id(params[:id]).collect do |pid|
      { :id => pid, :url => url("/objects/#{pid}") }
    end

    case content_type
    when :txt,
         :text  then result.collect { |v| v[:id] }.join("\n")
    when :xml   then render :query_by_id, :locals => { :data => result }
    when :json  then result.to_json
    end
  end
  
  post :label, :provides => [:json,:xml,:html] do
    result = params
    result['label'] = Dor::MetadataService.label_for(params[:source_id])
    case content_type
    when :json  then result.to_json
    when :xml   then result.to_xml
    when :html  then (request.xhr? ? partial('dor/register/label') : render('dor/register/label'))
    end
  end

end