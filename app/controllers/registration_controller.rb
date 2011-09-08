class RegistrationController < ApplicationController
  before_filter :authorize!
  
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
    docs = Dor::SearchService.gsearch(:q => %{PID:"#{params[:apo_id]}"})['response']['docs']
    format = docs.collect { |doc| doc['apo_metadata_format_field'] }.flatten.first.to_s
    forms = JSON.parse(RestClient.get('http://lyberapps-prod.stanford.edu/forms.json'))
    result = forms[format.downcase].to_a.sort { |a,b| a[1].casecmp(b[1]) }
    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => result }
    end
  end
  
  def workflow_list
    docs = Dor::SearchService.gsearch(:q => %{PID:"#{params[:apo_id]}"})['response']['docs']
    result = docs.collect { |doc| doc['apo_registration_workflow_field'] }.compact
    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => result.flatten.sort }
    end
  end

  def autocomplete
    response = Dor::SearchService.gsearch(:q => "*:*", :rows => '0', :facet => 'on', :'facet.field' => params[:field], :'facet.prefix' => params[:term].titlecase, :'facet.mincount' => 1, :'facet.limit' => 15)
    result = response['facet_counts']
    result = result['facet_fields']
    result = Hash[*(result['project_tag_facet'])].keys
    result.sort!
    respond_to do |format|
      format.any(:json, :xml) { render request.format.to_sym => result }
    end
  end
  
end
