class RegistrationController < ApplicationController
  
  def form
    redirect_to register_items_url
  end
  
  def tracksheet
    druids = Array(params[:druid])
    name = params[:name] || 'tracksheet'
    sequence = params[:sequence] || 1
    response['content-disposition'] = "attachment; filename=#{name}-#{sequence}.pdf"
    pdf = help.generate_tracking_pdf(druids)
    render :text => pdf.render, :content_type => :pdf
  end

  def form_list
    docs = Dor::SearchService.query(%{id:"#{params[:apo_id]}"}).hits
    format = docs.collect { |doc| doc['administrativeMetadata_metadata_format_t'] }.flatten.first.to_s
    forms = JSON.parse(RestClient.get('http://lyberapps-prod.stanford.edu/forms.json'))
    result = forms[format.downcase].to_a.sort { |a,b| a[1].casecmp(b[1]) }
    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => result }
    end
  end
  
  def workflow_list
    docs = Dor::SearchService.query(%{id:"#{params[:apo_id]}"}).hits
    result = docs.collect { |doc| doc['registration_workflow_id_t'] }.compact
    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => result.flatten.sort }
    end
  end

  def autocomplete
    response = Dor::SearchService.query('*:*', :rows => 0, :facets => { :fields => [params[:field]], :prefix => params[:term].titlecase, :mincount => 1, :limit => 15 })
    result = response.field_facets(params[:field]).collect { |f| f.name }.sort
    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => result }
    end
  end
  
end
